#!/bin/bash
yum update -y
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config