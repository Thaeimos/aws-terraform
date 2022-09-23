FROM ubuntu:22.04

# Google Cloud CLI
RUN apt-get update
RUN apt-get install -y curl gnupg apt-utils python3
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt-get update
RUN apt-get install -y apt-transport-https ca-certificates  google-cloud-cli

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

# Gcloud init at login
RUN echo 'gcloud init --console-only --skip-diagnostics' >> /root/.bashrc

# Use default Gcloud service account if no secret present. Otherwise, use secret for defined service account
RUN echo 'FILE="/home/gcp-prod-cons/secrets/service-account-credentials.json"\n\
if [ -f "$FILE" ]; then\n\
    echo "$FILE exists."\n\
    gcloud auth activate-service-account --key-file=$FILE\n\
    export GOOGLE_APPLICATION_CREDENTIALS="$FILE"\n\
else \n\
    echo "$FILE does not exist."\n\
    gcloud auth application-default login --no-launch-browser\n\
fi\n\
' >> /root/.bashrc

ENTRYPOINT ["/bin/bash"]