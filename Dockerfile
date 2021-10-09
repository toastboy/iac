# My unified Infrastructure as Code container image - a Jenkins agent which
# has Terraform, Packer & Ansible installed.

# Owes a debt to https://github.com/geektechdude/ansible_container/blob/master/Dockerfile

FROM jenkins/agent:stretch

USER root

# First, install Ansible

ADD ansible.list /etc/apt/sources.list.d/ansible.list
RUN APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt install -y ansible && \
    apt-get dist-upgrade -y && \
    apt-get clean all

ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING False
ENV ANSIBLE_RETRY_FILES_ENABLED False
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True

# Now Terraform

ADD https://releases.hashicorp.com/terraform/1.0.8/terraform_1.0.8_linux_amd64.zip /tmp/
RUN unzip -d /usr/local/bin/ /tmp/terraform_1.0.8_linux_amd64.zip && \
    chmod +x /usr/local/bin/terraform

# Add the self-signed certificate root from my vSphere installation

# See https://www.reddit.com/r/jenkinsci/comments/7y02v2/how_to_import_my_certificate_into_jenkins_when/
# and https://github.com/gliderlabs/docker-alpine/issues/260

ADD vsphere.crt /usr/local/share/ca-certificates/vsphere.crt
RUN update-ca-certificates

# Also packer

RUN  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common git xorriso && \
     curl -fsSL https://apt.releases.hashicorp.com/gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - && \
     apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
     apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y packer && apt-get clean all

ADD VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle .

RUN chmod +x VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle && \
    ./VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle --eulas-agreed

# Finally the tweaks in the jenkins user directory

USER jenkins

# Add Ansible galaxy packages

RUN ansible-galaxy collection install community.general community.crypto ansible.posix
