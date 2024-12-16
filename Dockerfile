FROM debian:bullseye-slim

# Install `openssh-server` and other dependencies
RUN apt update \
    && apt upgrade -y \
    && apt install openssh-server sudo vim-tiny ruby --yes \
    && rm -rf /var/lib/apt/lists/*

# Permit empty passwords
RUN sed -i 's/nullok_secure/nullok/' /etc/pam.d/common-auth
RUN echo "PermitEmptyPasswords yes" >> /etc/ssh/sshd_config

# Generate a workspace host key
RUN ssh-keygen -A
RUN chmod 775 /etc/ssh/ssh_host_rsa_key && \
    chmod 775 /etc/ssh/ssh_host_ecdsa_key && \
    chmod 775 /etc/ssh/ssh_host_ed25519_key

# Create a `gitlab-workspaces` user
RUN useradd -l -u 5001 -G sudo -md /home/gitlab-workspaces -s /bin/bash gitlab-workspaces
RUN passwd -d gitlab-workspaces
ENV HOME=/home/gitlab-workspaces
WORKDIR $HOME
RUN mkdir -p /home/gitlab-workspaces && chgrp -R 0 /home && chmod -R g=u /etc/passwd /etc/group /home

# Allow sign-in access to `/etc/shadow`
RUN chmod 775 /etc/shadow

# Create simple webpage and script which serves it via http server on port 8000
RUN mkdir -p /var/www
RUN echo '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Example HTTP Server</title></head><body>Example HTTP server</body></html>' > /var/www/index.html
RUN echo "ruby -run -ehttpd /var/www -p8000" > /usr/local/bin/server.sh
RUN chmod +x /usr/local/bin/server.sh

USER gitlab-workspaces

# Start ssh server (daemonized) as gitlab-workspaces user (not sudo) with:
# /usr/sbin/sshd
#
# Run web server (background) as gitlab-workspaces user (not sudo) with:
# nohup /usr/local/bin/server.sh > /tmp/server.log 2>&1 &
