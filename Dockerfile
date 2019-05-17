FROM ubuntu:18.04
LABEL maintainer="Sultan Gillani (sultangillani)"

ENV pip_packages "ansible yamllint ansible-lint"

ENV DEBIAN_FRONTEND noninteractive

WORKDIR /usr/local/bin

# Install dependencies.
RUN apt-get update &&  apt-get install -y --no-install-recommends \
       gnupg2 \
       python3-pip 
       python3-dev \
       build-essential \
       aptitude \
       software-properties-common \
       rsyslog \
       systemd \
       systemd-cron \
       sudo \
       openssl ca-certificates \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && pip3 install --upgrade pip setuptools \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && && rm -Rf /var/lib/apt/lists/*

RUN sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

# Cleanup unwanted systemd files -- See https://hub.docker.com/_/centos/
RUN find /lib/systemd/system/sysinit.target.wants/* ! -name systemd-tmpfiles-setup.service -delete; \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

# JDK Issue not sure whats up
RUN mkdir -p /usr/share/man/man1

# Install Ansible via Pip.
RUN pip install $pip_packages

COPY ansible-playbook-wrapper /usr/local/bin/

# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN printf "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

RUN useradd -ms /bin/bash ansible \
    && chown -R ansible:ansible /etc/ansible \
    && printf "ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /etc/ansible/roles/roles_to_test/tests

USER ansible
ENV TERM xterm
ENV ANSIBLE_CONFIG /etc/ansible/roles/roles_to_test/tests/ansible.cfg

VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]

CMD ["bash"]