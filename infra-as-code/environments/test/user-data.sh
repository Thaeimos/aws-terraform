#!/bin/bash
yum update -y
echo ECS_CLUSTER=my-cluster >> /etc/ecs/ecs.config