#!/bin/bash
yum update -y
curl https://s3.dualstack.eu-west-2.amazonaws.com/aws-xray-assets.eu-west-2/xray-daemon/aws-xray-daemon-3.x.rpm -o /home/ec2-user/xray.rpm
yum install -y /home/ec2-user/xray.rpm
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_WARM_POOLS_CHECK=true >> /etc/ecs/ecs.config