# terraform-init-envs

Terraform module to create the (Opinionated) directory structure for a project and create the backends to store the Terraform state and lock.
It will automatically create an .auto.tfvars files.

## Usage

Start up the [utilities](utilities/docker-image-bins/) docker image (which has already a section to properly configure your secrets), move into the "backends" directory and create a "terraform.tfvars" using "terraform.tfvars.example" as an example. The contents should be like:

```bash
environments         = ["dev","prod"]
s3_bucket_prefix     = "com.example"
s3_bucket_name       = "Dev Terraform State Store"
dynamodb_table       = "terraform_dev"
bucket_sse_algorithm = "AES256"
```

We favour the usage of ".tfvars" files and it's reflected in the code.

After you are done with this, issue the following command inside the "backends" directory:

```bash
cd backends
terraform init
terraform apply
```

The module will create buckets to store Terraform's remote configuration of each environment. Obviously, the state that is used to create those buckets is **local**.
You should have an "environments" folder with separated directories for each defined area, and a bucket for each environment, with prepopulated configurations that will store the remote state of each environment in the buckets created to do so.

Once you want to initialize any of the environments, traverse to it's folder and do the following commands:
```bash
cd environments/dev
terraform init -backend-config backend.tfvars
terraform apply
```

## TODO
- Make it work with GCP
- Complete utilities
- Create global variables and links to each environment