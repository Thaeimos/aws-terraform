#!/bin/bash
yum update -y
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_WARM_POOLS_CHECK=true >> /etc/ecs/ecs.config