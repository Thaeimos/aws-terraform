# Description

Docker image with a lot of binaries and tools needed for the development of the project.
This docker image assumes you've put your AWS credentials and preferences in the "secrets/login.secrets" file.


# Make this work

```bash
DOCKER_BUILDKIT=1 docker build -t aws-cli:v0 .
docker run -it aws-cli:v0
# Mount the contents of the repo inside the docker running process
cd ~/aws-terraform
docker run --mount type=bind,source="$(pwd)",target=/home/aws-terra -w /home/aws-terra -p 8080:8080 --name aws-docker-bins --rm -it aws-cli:v0
```

# Test all is OK
```bash
aws ec2 describe-hosts
{
    "Hosts": []
}
```