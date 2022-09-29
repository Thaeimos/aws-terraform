# aws-terraform

Terraform AWS demo using ECS


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

The idea is to create a scalable 3 tier web application with a database in the end spawning multiple availability zones in a given region, using ECS-EC2 as the frontend and ECS-Fragate as the application stack.


## Technologies Used

- Terraform - version 1.1.7
- Git       - version 2.37.2


## Features

List the ready features here:

- Infrastructure as code. Multiple environments to support different infrastructure choices.
- Monorepo. We have one folder for each application (Frontend and backend) and one folder for the infrastructure creation.
- Docker utility with all the commands and tools needed.
    - Use user's defined service account if present. Otherwise resort to default service account.
- IAM read-only users. Use this [link to connect](https://incode-test.signin.aws.amazon.com/console) to the account with the credentials provided. The code is in this [separated terraform file](/infra-as-code/environments/test/users.tf).
- ECS with EC2.
    - Dynamic AMI as you can see [here](/infra-as-code/environments/test/main.tf#L133).
    - Template substitution for user-data.sh.
- VPC
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
- External endpoint of type "application" for exposing the 3 tier web stack.
- Github pipelines to manage applications
    - Deploy on merge.
    - Pinned versions for external actions.
    - Use environments in GH:
        - We have different set of variables that, depending on the branch you are merging to, will have different values. Very useful when you wanna have a different set of credentials, for example, for your production and development environments.
- Documentation



## Screenshots



## Requirements



## Installation



## Usage



## Project Status
Project is: _Actively working_.


## Room for Improvement
Include areas you believe need improvement / could be improved. Also add TODOs for future development.

- Generate a VPC (VPC01) with private subnets, and the required subnets elements (Route tables, etc).

- Provision an application using ECS with EC2 and Fargate with the following elements: public component, private component, database component and all the required elements (security groups, roles, log groups, etc). The components must we interconnected, so for example the public layer must connect to the application layer and the application layer must connect to the database layer. A load balancer with target and auto-scalation groups must be utilized for each layer.
- For the database layer, use an AWS managed service.
- Select and add five CloudWatch alarms related to the implementation. We require explanation about the reasons of the selected alarms.
- A diagram with the implementation is required.
- Security
- Logging solution from ground up
- Monitoring solution from ground up
- Blue/Green deployments - https://docs.aws.amazon.com/AmazonECS/latest/developerguide/create-blue-green.html ?
- Test then prod
- Github pipelines
- Module pinning - Perhaps using https://github.com/philips-software/terraform-aws-ecs/tree/2.2.0 ?
- Generate MFA for read only users.
- Encrypt password for read only users.
- Use spot instances for EC2 ECS.
- Pin the AMI for ECS and provide information.
- SSL
    - Create certificates and attach them
    - Redirect http to https
- Docker proper credentials https://docs.docker.com/engine/reference/commandline/login/#credentials-store
- Substitute variables on task definition for AWS workflow
- Lint and security scan on PR on applications
 
- Create those using GH API https://stackoverflow.com/questions/70943164/create-environment-for-repository-using-gh
- Test ASGs front and back
- Docker scan in pipeline



## Acknowledgements
Give credit here.
- This project was inspired on the [Backend module for Terraform](https://github.com/DNXLabs/terraform-aws-backend).
- We used as a base this [medium article](https://medium.com/swlh/creating-an-aws-ecs-cluster-of-ec2-instances-with-terraform-85a10b5cfbe3).
- The inspiration for the spot instances [comes from here](https://github.com/aws-samples/ecs-refarch-mixed-mode/blob/master/README.md).
- For the user creation we used [this post](https://blog.gitguardian.com/managing-aws-iam-with-terraform-part-1/).
- Dynamic subnets creation based on this [Stackoverflow post](https://stackoverflow.com/questions/63309824/for-each-availability-zone-within-an-aws-region/63310014#63310014).
- We use code for the frontend and backend applications based on this [post](https://dev.to/eelayoubi/building-a-ha-aws-architecture-using-terraform-part-2-30gm).
- Heavily use of environments to segment variables, as explained in this [document](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment).



## Extras



## Contact
Created by [@thaeimos]

