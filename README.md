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
- IAM read-only users. Use this [link to connect](https://incode-test.signin.aws.amazon.com/console) to the account with the credentials provided. The code is in this [separated terraform file](/infra-as-code/environments/test/users.tf).

- VPC
    - Manually created instead using modules (Like https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=v3.16.0 for example - Pinned, of course)
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
    - S3, ECR and Cloudwatch VPC endpoints.
    - Healthcheck separated endpoint for target group.
    - Variable substitution using placeholders.
    - Use AWS Secrets Manager to put sensitive data in the templates and in the task.

- External endpoint of type "application" for exposing the 3 tier web stack.

- We've have added 5 alarms to monitor the application. Given the small number of alarms, we tend to focus on general behaviour of the whole stack instead of specific parts:
    - "target_response_time" to monitor the response time of the application. Useful if you deploy a new version and see it's more sluggish than the previous one. Also contributes to user satisfaction.
    - "error_rate" to monitor the number of bad responses we give to customers vs the total of responses. Generic workhorse for every web application monitoring.
    - "target_healthy_count_applications" to monitor the number of unhealthy tasks in the EC2 or Fargate cluster. We monitor both clusters in the same alarm. Useful to check if there are problems in any of the workloads. This is more specific than the previous two alerts.
    - "rds_cpu_utilization_too_high" and "rds_disk_free_storage_space_too_low" to monitor CPU and free space in our RDS database. I've honestly think this is the bare minimum for database monitoring and I feel nervous about having so few alarms for the database stack.

- Github pipelines to manage applications
    - Deploy on merge.
    - Pinned versions for external actions.
    - Use environments in GH:
        - We have different set of variables that, depending on the branch you are merging to, will have different values. Very useful when you wanna have a different set of credentials, for example, for your production and development environments.
        - We can create the environment and the secrets using the [instructions provided](/utilities/github-repo-setup/).
    - Variable substitution for the ECS tasks using secrets. Better centralized secret and variables storage and a lot of reusability.

- Documentation



## Architectural Diagram
![Architectural Diagram](/documents/architecture_diagram.png)



## Requirements



## Installation



## Usage



## Project Status
Project is: _Actively working_.


## Room for Improvement
Include areas you believe need improvement / could be improved. Also add TODOs for future development.

- Test then prod
- Github pipelines
    - Docker scan in pipeline
- Generate MFA for read only users.
- Encrypt password for read only users.
- Use spot instances for EC2 ECS.
- Pin the AMI for ECS and provide information.
- SSL
    - Create certificates and add them into AWS. We need to verify ownership of domain.
    - Create endpoint and attach the certificate.
    - Redirect http to https.
    - Create proper DNS name that points to the ELB DNS name.
- Docker multistage
- Cache in pipelines for docker
- Pipeline for IaC
- Lint and security scan on PR on applications


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



## Extras



## Contact
Created by [@thaeimos]

