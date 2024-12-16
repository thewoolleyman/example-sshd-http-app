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

- Create a buildx builder for multiplatform builds (linux and MacOS) `docker buildx create --use`
- Create a multiplatform build (for publishing to registry): `docker buildx build --platform linux/amd64,linux/arm64 -t example-sshd-http-app .`
- Also create a single-platform arm64 (MacOS) build, with `--load` option, to support local testing: `docker buildx build --platform linux/arm64 -t example-sshd-http-app-arm64 --load .`

## Testing the image locally

- Run the container locally: `docker run -it -p 8022:22 -p 8000:8000 --name local-sshd-http-app example-sshd-http-app-arm64 /bin/bash`
  - `-p 8022:22` maps the container's port 22 (sshd) to the host's port 8022
  - `-p 8000:8000` maps the container's port 8000 (web server) to the host's port 8000
- Connect to the container via bash: `docker exec -it local-sshd-http-app /bin/bash`
  - Run sshd daemonized: `/usr/sbin/sshd`
  - Run the HTTP server in the background: `/usr/local/bin/server.sh`
  - Tail the http server log: `tail -f /tmp/server.log`
- Test connecting to container via SSH from docker host machine: `ssh -p 8022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null gitlab-workspaces@localhost`
  - Connection should be successful with no password required.
- Test connecting to the container via HTTP from docker host machine. Access http://localhost:8000 in a browser 
- Remove the container: `docker rm -f local-sshd-http-app`

## Publish the image to registry and verify

- Tag and push the multiplatform build: `docker tag example-sshd-http-app registry.gitlab.com/gitlab-org/workspaces/examples/example-sshd-http-app:latest`
- `docker login registry.gitlab.com` (See https://docs.gitlab.com/ee/user/packages/container_registry/authenticate_with_container_registry.html for details)
- Tag and push the multiplatform build: `docker buildx build --platform linux/amd64,linux/arm64 -t registry.gitlab.com/gitlab-org/workspaces/examples/example-sshd-http-app:latest --push .`
- Verify the image was successfully pushed: https://gitlab.com/groups/gitlab-org/workspaces/examples/-/container_registries

## Running the image in GitLab Workspaces

- Open this project from https://gitlab.com/gitlab-org/workspaces/examples/example-sshd-http-app, or... 
- ...push it to a new project in your local GDK:
  - Create `example-sshd-http-app` project in GDK under `gitlab-org`, with no repo (no README)
  - From local machine: `git remote add gdk ssh://git@gdk.test:2222/gitlab-org/example-sshd-http-app.git`
  - Push to GDK: `git push gdk main:main`
- Create a new workspace for the project.
- NOTE: Currently, the `gitlab-workspaces-tools` container image does not support ARM64 (MacOS) architecture. To work around this in local GDK, you can locally edit `tools_injector_image` in `ee/lib/remote_development/settings/default_settings.rb` to have the following value: `registry.gitlab.com/gitlab-org/workspaces/testing/gitlab-workspaces-tools-arm-fork:arm64-latest`. Then, `gdk restart rails-web`, and create a new workspace for the `example-sshd-http-app` project.

## Debugging SSH connection issues

### In the tooling container

- Get workspace's namespace name: `kubectl get namespace`
- Get pod name: `kubectl get pods -n <namespace name>`  
- Exec into workspaces tooling container: `kubectl exec -it <pod name> -n <namespace name> -- /bin/bash`
- `ps -ef | grep sshd` to check if sshd is running
- To see logs, `kill -9` the `/usr/bin/sshd` PID, then run `/usr/sbin/sshd -d -D` to see sshd server output to console (TODO: Not sure where default logs go, find them and update this).

### In the gitlab-workspaces-proxy container

- Get `gitlab-workspaces-proxy` pod name: `kubectl get pods -n gitlab-workspaces`
- Tail the logs of the container: `kubectl logs -f gitlab-workspaces-proxy-79d845b49-hlxnv -c gitlab-workspaces-proxy -n gitlab-workspaces`
