# GA Settings DB - setup 
Setup instructions for Merkle GA Settings DB.


## Prerequisites
Ensure that you have:
- A GCP project with Billing enabled
- Access to the GCP project with the Owner role
- The GCP Project ID at hand

## Setup
1. Open Cloud Shell for the GCP Project where you like to setup GA Settings DB 
2. Run the following command:
    ```
    git clone https://github.com/Outfox/ga-settings-db-install.git 
    cd ga-settings-db-install 
    bash deploy.sh
    ```
3. Fill out info when asked (hit enter to use suggested default values)
4. Note the Service Account email created at the end of the setup
5. Assign the Service Account the 'Viewer' role in all Analytics accounts you like to monitor