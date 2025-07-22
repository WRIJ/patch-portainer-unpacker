# Portainer Compose Unpacker Patched

Provides patched Portainer Compose Unpacker image that triggers a webhook after
cloning a GitOps stack.

The service listening for this webhook must run on the same machine as the
**Portainer Agent** that manages the stack, and must use the exact same mount
path as the stack's local filesystem path.

## Usage

Swap the original Portainer Unpacker image with the patched one in your
Portainer stack. You can do this by setting an environment variable when
starting the **Portainer Server** container:

```sh
COMPOSE_UNPACKER_IMAGE=ghcr.io/wrij/portainer-unpacker:<TAG>
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

## Patching & Building

Use the `patch.sh` script to clone the Portainer and Compose Unpacker
repositories on the specified tag, and apply the patches:

```bash
./patch.sh 2.31.3
```

To patch & build the Portainer Compose Unpacker image, run:

```bash
./build.sh 2.31.3
```

In order to check if the patches are applied correctly, you can run the
following command:

```bash
docker run --rm -it compose-unpacker:2.31.3
```

The output should have the following line:

```
A patched tool to deploy Docker stacks from Git repositories.
```

## Releasing a new image

To publish a new version to the Docker registry, use GitHub Releases as follows:

1. Go to [GitHub Releases](https://github.com/WRIJ/patch-portainer-unpacker/releases/new) and create a new release.
2. Under **Choose a tag**, enter the new version number based on the Portainer verion (e.g. `2.27.9-patched`).
   - If this is the second release for the same Portainer version, append a sequence number (e.g. `2.27.9-patched.1`).
3. Click **Generate release notes** to automatically create a changelog based on pull requests merged since the previous release.
   - You can edit the release notes and add any extra relevant information.
4. Click **Publish release** to trigger the release (or **Save draft** if you are not ready to publish yet).
5. After publishing, a GitHub Actions workflow will automatically:
   - Build the new image.
   - Publish it to the Docker registry.
6. Once the workflow completes successfully, the new image version will be available for use.
