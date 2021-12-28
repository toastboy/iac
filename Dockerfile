# My unified Infrastructure as Code container image - a Jenkins agent which
# has Terraform, Packer & Ansible installed.

# Owes a debt to https://github.com/geektechdude/ansible_container/blob/master/Dockerfile

FROM jenkins/agent

USER root

# Set some Ansible defaults

ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING False
ENV ANSIBLE_RETRY_FILES_ENABLED False
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV ANSIBLE_STDOUT_CALLBACK debug

# Install Ansible, Terraform and Packer in the recommended ways

RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
            apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                git \
                gnupg \
                lsb-release \
                software-properties-common \
                xorriso
ADD ansible.list /etc/apt/sources.list.d/ansible.list
RUN APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 && \
    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt install -y ansible packer terraform && \
    apt-get clean all

# Add the self-signed certificate root from my vSphere installation

# See https://www.reddit.com/r/jenkinsci/comments/7y02v2/how_to_import_my_certificate_into_jenkins_when/
# and https://github.com/gliderlabs/docker-alpine/issues/260

ADD vsphere.crt /usr/local/share/ca-certificates/vsphere.crt
RUN update-ca-certificates

# Finally the OVF tool to create VMware VM images

ADD VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle /tmp/
RUN chmod +x /tmp/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle && \
    /tmp/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle --eulas-agreed

# Make sure everything is up to date

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get clean all

# Finally the tweaks in the jenkins user directory

USER jenkins

# Add Ansible galaxy packages

RUN ansible-galaxy collection install community.general community.crypto ansible.posix
