FROM ubuntu:22.04

# Common packages
RUN apt-get update
RUN apt-get install -y apt-transport-https ca-certificates curl gnupg apt-utils python3 git

# Kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl
RUN kubectl version --client

# Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN ./get_helm.sh
RUN echo 'source <(helm completion bash)' >> /root/.bashrc

# Add bash-completion, jq and vim
RUN apt-get install -y bash-completion vim jq
RUN echo 'source /usr/share/bash-completion/bash_completion' >> /root/.bashrc
RUN echo 'source <(kubectl completion bash)' >> /root/.bashrc

# Terraform
RUN apt-get update
RUN apt-get install -y gnupg2 software-properties-common lsb-release gnupg wget unzip
RUN wget https://releases.hashicorp.com/terraform/1.1.7/terraform_1.1.7_linux_$(dpkg --print-architecture).zip
RUN unzip terraform_1.1.7_linux_$(dpkg --print-architecture).zip
RUN mv terraform /usr/local/bin/
RUN echo 'complete -C /usr/local/bin/terraform terraform' >> /root/.bashrc

# Install AWS CLI
RUN apt-get install -y less groff glibc-source
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install -i /usr/local/aws-cli -b /usr/local/bin
# Auto-complete
RUN echo 'complete -C /usr/local/bin/aws_completer aws ' >> ~/.bashrc

# AWS login - Copy secrets from secret and untracked folder
COPY secrets/login.secrets /tmp/
RUN mkdir ~/.aws
RUN sed -n '2,4p' /tmp/login.secrets > ~/.aws/credentials
RUN sed -n '7,9p' /tmp/login.secrets > ~/.aws/config
RUN rm /tmp/login.secrets

ENTRYPOINT ["/bin/bash"]