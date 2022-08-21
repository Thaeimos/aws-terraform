# Instructions

## Create the bucket for the backend state
Be sure to have configured the AWS CLI first, since we use some of its configuration paramenters.

```bash
TRAIL=$(echo $RANDOM | md5sum | head -c 8; echo;)
REGION=$(awk -F "=" '/region/ {print $2}' ~/.aws/config)
aws s3api create-bucket --bucket terraform-backend-$TRAIL --acl private --region $REGION --create-bucket-configuration LocationConstraint=$REGION
```

## Update the configuration in the tfvars file