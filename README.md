# Example sshd and HTTP server App

**DISCLAIMER: This image is solely for example purposes, it may not be maintained or continue working.**

This project contains the following:
- a Dockerfile which builds a container which:
  - is based on https://hub.docker.com/r/linuxserver/openssh-server
  - is [configured for ssh connections in GitLab Workspaces](https://docs.gitlab.com/ee/user/workspace/configuration.html#update-your-workspace-container-image)
  - contains `ruby` installed
  - a `/usr/local/bin/server.sh` script which starts a [simple ruby HTTP server on port 8000](https://gist.github.com/willurd/5720255#ruby-192) using `HTTP::Server::Brick` via `ruby`:
  - `ruby -run -ehttpd . -p8000`
- a `.devfile.yaml` to run this project in [GitLab Workspaces](https://docs.gitlab.com/ee/user/workspace/)

# Developer notes

## Building the image

- `docker build -t example-sshd-http-app .`

## Testing the image locally

- Run the container locally: `docker run -it -p 2222:22 -p 8000:8000 --name local-sshd-http-app example-sshd-http-app /bin/bash`
  - `-p 2222:22` maps the container's port 22 (sshd) to the host's port 2222
  - `-p 8000:8000` maps the container's port 8000 (web server) to the host's port 8000
- Connect to the container via bash: `docker exec -it local-sshd-http-app /bin/bash`
  - Run sshd daemonized: `/usr/sbin/sshd`
  - Run the HTTP server in the background: `/usr/local/bin/server.sh`
  - Tail the http server log: `tail -f /tmp/server.log`
- Test connecting to container via SSH from docker host machine: `ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null gitlab-workspaces@localhost`
  - Connection should be successful with no password required.
- Test connecting to the container via HTTP from docker host machine. Access http://localhost:8000 in a browser 
- Remove the container: `docker rm -f local-sshd-http-app`

## Publish the image to registry and verify

- `docker tag example-sshd-http-app registry.gitlab.com/gitlab-org/workspaces/examples/example-sshd-http-app:latest`
- `docker login registry.gitlab.com` (See https://docs.gitlab.com/ee/user/packages/container_registry/authenticate_with_container_registry.html for details)
- `docker push registry.gitlab.com/gitlab-org/workspaces/examples/example-sshd-http-app:latest`
- Verify the image was successfully pushed: https://gitlab.com/groups/gitlab-org/workspaces/examples/-/container_registries
- Remove the local copy of the image: `docker rmi registry.gitlab.com/gitlab-org/workspaces/examples/example-sshd-http-app:latest`  
- Pull the image locally and run with the above local testing steps, replacing `example-sshd-http-app` with `registry.gitlab.com/gitlab-org/workspaces/examples/example-sshd-http-app:latest` in the `docker run` command.
