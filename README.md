# aws-terraform

Multicloud setup using Terraform in AWS and GCP


## Table of Contents

* [General Info](#general-information)
* [Technologies Used](#technologies-used)
* [Features](#features)
* [Screenshots](#screenshots)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Project Status](#project-status)
* [Room for Improvement](#room-for-improvement)
* [Acknowledgements](#acknowledgements)
* [Extras](#extras)
* [Contact](#contact)


## General Information

This is for my own practice and trainning.

The idea is to create a scalable web monitor application that feeds information about website availability over a GCP's Pub/Sub instance to be inserted  into an SQL database, yet to be determined.


## Technologies Used

- Terraform - version 1.1.7
- Git       - version 2.37.2


## Features

List the ready features here:

- Infrastructure as code
- Monorepo
- Docker utility with all the commands and tools needed
    - Use user's defined service account if present. Otherwise resort to default service account.
- Documentation


## Screenshots




## Requirements

-


## Installation

First, create a project in AWS so we can start creating the infrastructure in it.
Later, we will need to authenticate to Gcloud using their CLI. We could use the [Docker image](utilities/docker-image-bins/) to that end.
After that's done, we need to create the service account and the bucket where we are gonna store the Terraform state for the infrastructure. In order to achieve that, here is a snipet in bash that does so:

```bash
# Set project
# PROJECTID="<YOUR-PROJECT-UNIQUE-ID>"
PROJECTID="muscia-test"
gcloud config set project $PROJECTID

# Set region and zone - Use 'gcloud compute zones list' to check options
LOCATION_REGION="europe-west1"
LOCATION_ZONE="europe-west1-b"
gcloud config set compute/region $LOCATION_REGION
gcloud config set compute/zone $LOCATION_ZONE

# Grant permission to the build API
gcloud services enable iam.googleapis.com appengine.googleapis.com bigquery.googleapis.com bigquerystorage.googleapis.com cloudapis.googleapis.com clouddebugger.googleapis.com cloudresourcemanager.googleapis.com cloudtrace.googleapis.com containerregistry.googleapis.com datastore.googleapis.com logging.googleapis.com monitoring.googleapis.com pubsub.googleapis.com servicemanagement.googleapis.com serviceusage.googleapis.com sql-component.googleapis.com storage-api.googleapis.com storage-component.googleapis.com storage.googleapis.com

# Create service account and grant the necessary permissions
ACCOUNT_NAME="cloud-build-${PROJECTID}"
gcloud iam service-accounts create ${ACCOUNT_NAME} --display-name "${ACCOUNT_NAME}" --description "Service account used for ${PROJECTID} in GitHub and deploying in" 

# We need to assign the roles one by one, hence the loop
LISTROLES=( storage.admin viewer iam.serviceAccountUser cloudbuild.builds.editor appengine.appCreator appengine.appAdmin pubsub.editor cloudfunctions.admin serviceusage.serviceUsageAdmin )
for ROLE in "${LISTROLES[@]}"; do gcloud projects add-iam-policy-binding ${PROJECTID} --member="serviceAccount:${ACCOUNT_NAME}@${PROJECTID}.iam.gserviceaccount.com" --role="roles/${ROLE}"; done

# Create credentials for that service account
gcloud iam service-accounts keys create secrets/service-account-credentials.json --iam-account ${ACCOUNT_NAME}@${PROJECTID}.iam.gserviceaccount.com

# Create the bucket for the Terraform state with a unique name
RANDOM_VALUE=$(cat /proc/sys/kernel/random/uuid | sed 's/[-]//g' | head -c 8)
gsutil mb -c standard -l europe-west1 gs://bucket-tf-${PROJECTID}-${RANDOM_VALUE}

# Give permissions for the Pub/Sub service account
gcloud projects add-iam-policy-binding ${PROJECTID} --member=serviceAccount:service-<PROJECT-NUMBER-ID>@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator
```




## Usage

### Producer simple usage



## Project Status
Project is: _Getting started_.


## Room for Improvement
Include areas you believe need improvement / could be improved. Also add TODOs for future development.

Room for improvement:
- Create cloud scheduler and test all works
    - Be sure only scheduler can trigger it
    - Fix role permission to delegated SA about creating additional SA
- Restrict API creation on the start and put it in Terraform
- Terraform IaC
    - Improve way to auto configure bucket for state
    - Usage for terraform.tfvars?
    - PubSub permissions in README?
    - Terraform testing
- Makefiles
- Show data for web services in a Grafana


## Acknowledgements
Give credit here.
- This project was inspired on the [Backend module for Terraform](https://github.com/DNXLabs/terraform-aws-backend).



## Extras
### GCP roles 
```bash
# Login as service account and use it's permissions on the gcloud CLI
gcloud auth activate-service-account --key-file=../secrets/service-account-credentials.json

# List service accounts
gcloud iam service-accounts list

# Gets roles for a service account
gcloud projects get-iam-policy <YOUR GCLOUD PROJECT> --flatten="bindings[].members" \
--format='table(bindings.role)' --filter="bindings.members:<YOUR SERVICE ACCOUNT>"
# Example
gcloud projects get-iam-policy muscia-test --flatten="bindings[].members" --format='table(bindings.role)' --filter="bindings.members:cloud-build-muscia-test"

# List roles for the ORG
gcloud iam roles list --organization ORG_ID

# Add role 
gcloud projects add-iam-policy-binding muscia-test --member="serviceAccount:cloud-build-muscia-test@muscia-test.iam.gserviceaccount.com" --role="roles/cloudfunctions.admin"
```


## Contact
Created by [@thaeimos]

