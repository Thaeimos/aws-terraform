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



## Installation



## Usage



## Project Status
Project is: _Getting started_.


## Room for Improvement
Include areas you believe need improvement / could be improved. Also add TODOs for future development.

- Generate temporal IAM read-only users
- Generate a VPC (VPC01) with public and private subnets, and the required subnets elements (Route tables, Internet gateways, NAT or instance gateways, etc).
- Provision an application using ECS with EC2 and Fargate with the following elements: public component, private component, database component and all the required elements (security groups, roles, log groups, etc). The components must we interconnected, so for example the public layer must connect to the application layer and the application layer must connect to the database layer. A load balancer with target and auto-scalation groups must be utilized for each layer.
- For the database layer, use an AWS managed service.
- Expose the application to Internet using a load balancer of the type you consider the best for this kind of implementation. No need to assign a domain name or TLS certificates, but explanation of what is required to do it will be necessary.
- Select and add five CloudWatch alarms related to the implementation. We require explanation about the reasons of the selected alarms.
- A diagram with the implementation is required.
- Create directory structure for single region.
- Escalate that to multi region.



## Acknowledgements
Give credit here.
- This project was inspired on the [Backend module for Terraform](https://github.com/DNXLabs/terraform-aws-backend).
- We used as a base this [medium article](https://medium.com/swlh/creating-an-aws-ecs-cluster-of-ec2-instances-with-terraform-85a10b5cfbe3).
- The inspiration for the spot instances [comes from here](https://github.com/aws-samples/ecs-refarch-mixed-mode/blob/master/README.md).



## Extras



## Contact
Created by [@thaeimos]

