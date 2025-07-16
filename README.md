# Portainer Unpacker

A patched Portainer Unpacker image that triggers a webhook after cloning
a GitOps stack.

The service listening for this webhook must run on the same machine as the
**Portainer Agent** that manages the stack, and must use the exact same mount
path as the stack's local filesystem path.

## Usage

Swap the original Portainer Unpacker image with the patched one in your
Portainer stack. You can do this by setting an environment variable when
starting the **Portainer Server** container:

```sh
COMPOSE_UNPACKER_IMAGE=<TBD>:<TAG>
```

Configure the Portainer Unpacker service (this service) by placing a
`webhooks.json` file in the root of the local filesystem path you configured
for your GitOps stack(s).

Consult the Portainer Agent documentation for more details about
[relative path support](https://docs.portainer.io/advanced/relative-paths).

The `webhooks.json` file should contain the URL of the webhook you want to
call after the clone operation is completed. For example:

```json
{
  "postClone": {
      "url": "http://172.17.0.1:<PORT>/portainer/postClone"
  }
}
```

Note: This uses the Docker bridge IP so the Portainer Unpacker container can
      reach the service. This service must either run on the same host or be a
      Docker container with a port mapping to receive the webhook call.

Note: The webhook call is currently not secured. Ensure that the service is only
      accessible from trusted sources.

## Development

This repository contains a VSCode devcontainer configuration, which allows you
to develop inside a containerized environment directly from VSCode.

The only prerequisite is having a functional installation of Docker on your
local machine.

## Building

To build a new image run the build script with the version of Portainer Unpacker
you want to patch, for example:

```bash
./build.sh 2.31.3
```
