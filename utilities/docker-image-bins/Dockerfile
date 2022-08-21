FROM ubuntu:22.04

# AWS CLI
RUN apt-get update
RUN apt-get install -y apt-transport-https ca-certificates curl gnupg apt-utils python3 awscli

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
RUN echo 'complete -C /usr/bin/terraform terraform' >> /root/.bashrc

# AWS init at login

ENTRYPOINT ["/bin/bash"]