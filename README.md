# aws-terraform

Terraform AWS demo using ECS


## Table of Contents

* [General Info](#general-information)
* [Technologies Used](#technologies-used)
* [Features](#features)
* [Screenshots](#architectural-diagram)
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

The idea is to create a scalable 3 tier web application with a database in the end spawning multiple availability zones in a given region, using ECS-EC2 as the frontend and ECS-Fragate as the application stack.


## Technologies Used

- Terraform - version 1.1.7
- Git       - version 2.37.2


## Features

List the ready features here:

- Infrastructure as code. Multiple environments to support different infrastructure choices.
    - No usage of count. We favour "for_each" instead because of [this reason](https://medium.com/@business_99069/terraform-count-vs-for-each-b7ada2c0b186).

- Monorepo. We have one folder for each application (Frontend and backend) and one folder for the infrastructure creation.
- Docker utility with all the commands and tools needed.
    - Use user's defined service account if present. Otherwise resort to default service account.

- IAM read-only users. Use this [link to connect](https://incode-test.signin.aws.amazon.com/console) to the account with the credentials provided. The code is in this [separated terraform file](/infra-as-code/environments/production/users.tf).

- VPC
    - Manually created instead using modules (Like https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=v3.16.1 for example - Pinned, of course)
    - Name as desired (VPC01).
    - Dynamic public and private subnets creation based on Availability Zones.
    - Route tables to support the subnets.
    - Internet gateway so the frontend components can talk to the exterior.
    - Variable that tags the environment.
    - Create log partitions for applications.

- Frontend application using ECS (EC2) as a public component with:
    - Security groups.
    - Roles.
    - Cloudwatch log group.
    - Load balancer.
    - Auto-scalation group.
        - Warm up instances included for rapid scale outs.
    - Dynamic AMI defined.
    - Template substitution for EC2 instances in user-data.sh.
    - Variable substitution using placeholders.
    - Use AWS Secrets Manager to put sensitive data in the templates and in the task.
    - Healthcheck separated endpoint for target group.

- Backend application using ECS (Fargate) as an application component with:
    - Security groups.
    - Roles.
    - Cloudwatch log group.
    - Load balancer.
    - Auto-scalation application target.
    - No route to the exterior. NAT Gateway doesn't have any routes on the private subnets.
    - S3, ECR, Secrets Manger and Cloudwatch VPC endpoints so the private network without access to Internet can talk to those services.
    - Healthcheck separated endpoint for target group.
    - Variable substitution using placeholders.
    - Use AWS Secrets Manager to put sensitive data in the templates and in the task.
    - Internal repo for Xray to be able to be deployed in internal subnets, given no route to the exterior.

- External endpoint of type "application" for exposing the 3 tier web stack.

- We've have added 5 alarms to monitor the application. Given the small number of alarms, we tend to focus on general behaviour of the whole stack instead of specific parts:
    - "target_response_time" to monitor the response time of the application. Useful if you deploy a new version and it's more sluggish than the previous one. Also contributes to user satisfaction.
    - "error_rate" to monitor the number of bad responses we give to customers vs the total of responses. Generic workhorse for every web application monitoring.
    - "target_healthy_count_applications" to monitor the number of healthy tasks in the EC2 or Fargate cluster. We monitor both clusters in the same alarm. Useful to check if there are problems in any of the workloads. This is more specific than the previous two alerts.
    - "rds_cpu_utilization_too_high" and "rds_disk_free_storage_space_too_low" to monitor CPU and free space in our RDS database. I honestly think this is the bare minimum for database monitoring and I feel nervous about having so few alarms for the database stack.

- Github pipelines to manage applications
    - Deploy on merge.
    - Deploy Infrastructure as Code. You can see an example [here](https://github.com/Thaeimos/aws-terraform/actions/runs/3185190823).
    - Pinned versions for external actions.
    - Use environments in GH:
        - We have different set of variables that, depending on the branch you are merging to, will have different values. Very useful when you wanna have a different set of credentials, for example, for your production and development environments.
        - We can create the environment and the secrets using the [instructions provided](/utilities/github-repo-setup/).
    - Variable substitution for the ECS tasks using secrets. Better centralized secret and variables storage and a lot of reusability.
    - Lint and security scan on PR on applications. You can see a scanner that raised an issue [here](https://github.com/Thaeimos/aws-terraform/actions/runs/3190795246/jobs/5206360466). The scanner passed on this [execution](https://github.com/Thaeimos/aws-terraform/actions/runs/3224905581/jobs/5276567702#step:12:7). Full run completed OK [here](https://github.com/Thaeimos/aws-terraform/actions/runs/3262615739/jobs/5359974786).

- Documentation



## Architectural Diagram
![Architectural Diagram](/documents/architecture_diagram.png)



## Requirements
N/A


## Installation
N/A


## Usage


### Deploy infrastructure
First we need to deploy the infrastructure. There are several environments created for this but only one is [active](/infra-as-code/environments/production/). We move into that folder and we fill up the necessary information to connect to the remote bucket that will contain our state:

```bash
cat backend.tfvars.example
    bucket              = "sre-challenge-test"
    dynamodb_table      = "test-dqwdw"
    encrypt             = false
    region              = "us-west-2"
    key                 = "sre"
```

The file that we should put our information should be called "backend.tfvars".
Once that's done, we can initialize our environment to connect to the remote state:

```bash
terraform init -backend-config backend.tfvars
```

Moving forward, we should fill up a "terraform.tfvars" file similar to the example provided, so we can add the values needed to our variables in the manifests:

```bash
cat terraform.tfvars.example
    region                  = "us-east-1"
    read_only_users         = ["test-01","test-01"]
    main_cidr_block         = "10.0.0.0/16"
    environment             = "dev"
    frontend_name           = "frontend-app"
    backend_name            = "backend-app"
    db_username             = "db_user"
    db_password             = "th3_p4assw0rd"
```

And the config should be done, we just need to apply it with:

```bash
terraform apply # -auto-approve # Only for the brave
```

### Deploy frontend application
This should be done automatically with the Github workflows provided. Just do a bogus change in one of the files inside the [frontend folder](/frontend-app/) and commit and push and it should deploy automatically.

### Deploy backend application
This should be done automatically with the Github workflows provided. Just do a bogus change in one of the files inside the [backend folder](/backend-app/) and commit and push and it should deploy automatically.

### Test
We can use curl commands to the external load balancer and get their responses to see if all is working.

For example, to get a pure frontend response and see the values of some variables and bogus secrets, you can do the following:
```bash
curl http://sre-challenge-front-end-lb-820694651.eu-west-2.elb.amazonaws.com/
    Hello from ip-10-0-1-181.eu-west-2.compute.internal
    The loadbalancer for the backend is internal-sre-challenge-back-end-lb-234524435.eu-west-2.elb.amazonaws.com
    The environment value is production
    The secret value is incode_user
```

To see a full interaction between the three stacks (Frontend, backend and database), you can call this endpoint:
```bash
curl http://sre-challenge-front-end-lb-820694651.eu-west-2.elb.amazonaws.com/users | jq ''
    ...
    [
    {
        "id": 1,
        "lastname": "Tony",
        "firstname": "Sam",
        "email": "tonysam@whatever.com"
    },
    {
        "id": 2,
        "lastname": "Doe",
        "firstname": "John",
        "email": "john.doe@whatever.com"
    }
    ...
```

If we want to test if the alarm for the error rate is working, we can just issue a request to a non existant endpoint and check the AWS Cloudwatch dashboard:
```bash
curl http://sre-challenge-front-end-lb-820694651.eu-west-2.elb.amazonaws.com/500r4
404 not found
```

Do N requests to stage a batch of testing:
```bash
ENDPOINT="http://sre-challenge-front-end-lb-1075719271.eu-west-2.elb.amazonaws.com"
for INT in {1..10}; do curl $ENDPOINT/users; done
```

### Delete all infrastructure except unique resources

If we want to destroy everything that's costing money, but want to keep the unique resources, like a bucket with a unique name or a login policy that will change the password, this is a convoluted way for not tracking those resources by Terraform, and the attach those back to the state.
Your identifiers will vary greatly, so a versioned state will be your ally here.

```bash
# Remove from state the things we don't want to destroy
terraform state rm 'aws_iam_user.user["carlos-gutierrez-01"]'
terraform state rm 'aws_iam_user.user["sean-head-01"]'
terraform state rm 'aws_iam_user_group_membership.devstream["carlos-gutierrez-01"]'
terraform state rm 'aws_iam_user_group_membership.devstream["sean-head-01"]'
terraform state rm 'aws_iam_user_login_profile.user_login["carlos-gutierrez-01"]'
terraform state rm 'aws_iam_user_login_profile.user_login["sean-head-01"]'
terraform state rm aws_iam_group_policy_attachment.read_only
terraform state rm aws_iam_group.read_only
terraform state rm aws_iam_account_password_policy.medium
terraform state rm aws_secretsmanager_secret.secretmasterDB

# Destroy everything else
terraform destroy -auto-approve

# Import back the resources we dettached from the state
terraform import 'aws_iam_user.user["carlos-gutierrez-01"]' carlos-gutierrez-01
terraform import 'aws_iam_user.user["sean-head-01"]' sean-head-01
terraform import 'aws_iam_user_group_membership.devstream["carlos-gutierrez-01"]' carlos-gutierrez-01/read-only-users
terraform import 'aws_iam_user_group_membership.devstream["sean-head-01"]' sean-head-01/read-only-users
terraform import 'aws_iam_user_login_profile.user_login["carlos-gutierrez-01"]' carlos-gutierrez-01
terraform import 'aws_iam_user_login_profile.user_login["sean-head-01"]' sean-head-01
terraform import aws_iam_group_policy_attachment.read_only read-only-users/arn:aws:iam::aws:policy/ReadOnlyAccess
terraform import aws_iam_group.read_only read-only-users
terraform import aws_iam_account_password_policy.medium iam-account-password-policy
terraform import aws_secretsmanager_secret.secretmasterDB arn:aws:secretsmanager:eu-west-2:790577265452:secret:db-credentials-nBqpSq
```


## Project Status
Project is: _Actively working_.


## Room for Improvement
Include areas you believe need improvement / could be improved. Also add TODOs for future development.

- Use testing area and then deploy to production.
- Generate MFA for read only users.
- Encrypt password for read only users.
- Use spot instances for EC2 ECS.
- Pin the AMI for ECS and provide information.
- SSL
    - Create certificates and add them into AWS. We need to verify ownership of domain.
    - Create endpoint and attach the certificate.
    - Redirect http to https.
    - Create proper DNS name that points to the ELB DNS name.
- Docker multistage.
- Cache in pipelines for docker.
- XRAY on backend application.


## Acknowledgements
Give credit here.

- This project was inspired on the [Backend module for Terraform](https://github.com/DNXLabs/terraform-aws-backend).
- We used as a base this [medium article](https://medium.com/swlh/creating-an-aws-ecs-cluster-of-ec2-instances-with-terraform-85a10b5cfbe3).
- The inspiration for the spot instances [comes from here](https://github.com/aws-samples/ecs-refarch-mixed-mode/blob/master/README.md).
- For the user creation we used [this post](https://blog.gitguardian.com/managing-aws-iam-with-terraform-part-1/).
- Dynamic subnets creation based on this [Stackoverflow post](https://stackoverflow.com/questions/63309824/for-each-availability-zone-within-an-aws-region/63310014#63310014).
- We use code for the frontend and backend applications based on this [post](https://dev.to/eelayoubi/building-a-ha-aws-architecture-using-terraform-part-2-30gm).
- Heavily use of environments to segment variables, as explained in this [document](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment).
- Inspiration for internal ECRs and other comes from this [article](https://dev.to/danquack/private-fargate-deployment-with-vpc-endpoints-1h0p) and this [other](https://hands-on.cloud/how-to-launch-aws-fargate-cluster-tasks-in-private-subnets/) as well.
- AWS Xray integration is partially based on this [repository](https://github.com/aws-samples/aws-xray-sdk-node-sample/blob/master/index.js). The [official documentation](https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-nodejs.html) also helped.



## Extras



## Contact
Created by [@thaeimos]

