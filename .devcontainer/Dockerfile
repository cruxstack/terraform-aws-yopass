FROM mcr.microsoft.com/vscode/devcontainers/base:1-focal

# Install AWS CLI
RUN apt-get update && \
    apt-get install -y unzip python3-pip && \
    pip3 install --no-cache-dir --upgrade awscli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js
ENV NODE_VERSION=18.x
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - && \
    apt-get install -y nodejs && \
    npm install -g typescript

# Install Docker CLI
COPY --from=docker:dind /usr/local/bin/docker /usr/local/bin/

# Install Terraform
ENV TERRAFORM_VERSION=1.5.1
ENV TF_PLUGIN_CACHE_DIR=$HOME/.terraform.d/plugin-cache
RUN SYSTEM_ARCH=$(dpkg --print-architecture) \
    && mkdir -p $TF_PLUGIN_CACHE_DIR \
    && curl -OL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${SYSTEM_ARCH}.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_${SYSTEM_ARCH}.zip \
    && mv terraform /usr/local/bin/ \
    && terraform version \
    && rm terraform_${TERRAFORM_VERSION}_linux_${SYSTEM_ARCH}.zip

# Install Open Policy Agent
RUN wget https://github.com/open-policy-agent/opa/releases/latest/download/opa_linux_amd64 -O /usr/local/bin/opa && \
    chmod +x /usr/local/bin/opa

# Verify Installs
RUN terraform --version \
    && aws --version \
    && node --version \
    && npm --version \
    && opa version \
    && tsc --version \
    && docker --version
