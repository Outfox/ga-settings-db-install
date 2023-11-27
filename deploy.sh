# -------------------------------------------------------------------
# Setup of GA Settings DB
# -------------------------------------------------------------------

read -p "Enter Google Cloud Project ID: " project_id
if [ -z "$project_id" ]
then
    echo "Cloud Project ID is required!"
    read -p "Enter Google Cloud Project ID: " project_id
fi

read -p "Enter Cloud Run region [europe-west1] (hit enter for default): " region
region=${region:-europe-west1}

read -p "Enter BigQuery dataset name [ga_settings] (hit enter for default): " dataset
dataset=${dataset:-ga_settings}

read -p "Enter BigQuery dataset region [EU] (hit enter for default): " bq_region
bq_region=${bq_region:-EU}

read -p "Enter service account name [ga-settings-db] (hit enter for default): " sa_name
sa_name=${sa_name:-ga-settings-db}

# Set project:
gcloud config set project $project_id

# Activate GA Admin API:
gcloud services enable analyticsadmin.googleapis.com

# Create Service Account:
gcloud iam service-accounts create $sa_name \
    --display-name="Google Analytics Settings DB." \
    --description="Monitors settings for GA accounts and properties."

# Assign roles to SA: 
gcloud projects add-iam-policy-binding ${project_id} \
    --member=serviceAccount:${sa_name}@${project_id}.iam.gserviceaccount.com \
    --role=roles/bigquery.admin
gcloud projects add-iam-policy-binding ${project_id} \
    --member=serviceAccount:${sa_name}@${project_id}.iam.gserviceaccount.com \
    --role=roles/run.invoker
gcloud projects add-iam-policy-binding ${project_id} \
    --member=serviceAccount:${sa_name}@${project_id}.iam.gserviceaccount.com \
    --role=roles/logging.logWriter


# Create Cloud Run Job:
gcloud run jobs create ga-settings-db \
    --image=europe-west1-docker.pkg.dev/merkle-ga-settings-db/ga-settings-db/settings-download-job:latest \
    --tasks=1 \
    --max-retries=0 \
    --region=$region \
    --task-timeout=60m \
    --service-account=${sa_name}@${project_id}.iam.gserviceaccount.com \
    --set-env-vars="PROJECT_ID=${project_id}" \
    --set-env-vars="BQ_DATASET=${dataset}" \
    --set-env-vars="BQ_REGION=${bq_region}" 


# Schedule job:
gcloud scheduler jobs create http ga-settings-db \
    --location=${region} \
    --schedule="0 22 * * *" \
    --uri="https://${region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${project_id}/jobs/ga-settings-db:run" \
    --http-method=POST \
    --oauth-service-account-email=${sa_name}@${project_id}.iam.gserviceaccount.com


cat << EOF
********************************
Setup completed!!

Remember to grant the service account (${sa_name}@${project_id}.iam.gserviceaccount.com) read permissions in all your Google Analytics accounts.
********************************
EOF