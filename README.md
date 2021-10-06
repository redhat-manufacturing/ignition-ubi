# Ignition 8.1.x Docker Image

If you're on Linux/macOS, you can build this image using the supplied Makefile to automate the docker image build.  There are a few build targets defined for your convenience, as outlined below.  

_NOTE: there are also build targets in the parent directory that can be used to build multiple branches (e.g. 7.9.x and 8.0.x).  They leverage the build targets mentioned here._

## Single Architecture Local Builds

To build both the _FULL_ and _EDGE_ editions locally (with a custom tag) against your native architecture:

    $ make build BASE_IMAGE_NAME=custom/ignition

This will create images `custom/ignition` with tags `8.1.x`, and `8.1` (based on the current version).

You can also specify a registry target for the `BASE_IMAGE_NAME` so you can then push those images to your custom Docker image registry:

    $ make build BASE_IMAGE_NAME=localhost:5000/custom/ignition
    $ make push-registry

... which will build and push images to the registry running at `localhost:5000`.

If you just want to build the _FULL_ image, you can specify one of the alternative build targets:

    $ make .build-full BASE_IMAGE_NAME=custom/ignition

## Multi Architecture Local Builds

There is some potential additional setup that you need to perform to get your environment setup for multi-architecture builds (consult the `.travis.yml` in the main directory for some insight), but once you're ready, it is fairly easy to conduct.  Multi-architecture builds **DO REQUIRE** a registry to push to, so keep that in mind.  The default build will target a local registry at `localhost:5000`:

    $ make multibuild

If you need to target a different registry, just override the `BASE_IMAGE_NAME` like below:

    $ make multibuild BASE_IMAGE_NAME=myregistry:5000/kcollins/ignition

## Start an Ignition Maker Edition gateway instance (UBI Image)

To run the Ignition Maker Edition variant, supply some additional environment variables with the container launch. You'll need to acquire a Maker Edition license from Inductive Automation to use this image variant. More information [here](https://inductiveautomation.com/ignition/maker-edition).

- `IGNITION_EDITION=maker` - Specifies Maker Edition
- `IGNITION_LICENSE_KEY=ABCD_1234` - Supply your license key
- `IGNITION_ACTIVATION_TOKEN=xxxxxxx` - Supply your activation token

Run the container with these extra environment variables:

```bash
podman run -p 8088:8088 \
--name my-ignition-maker --privileged \ 
-e GATEWAY_ADMIN_PASSWORD=password \
-e IGNITION_EDITION=maker \ 
-e IGNITION_LICENSE_KEY=ABCD_1234 \
-e IGNITION_ACTIVATION_TOKEN=asdfghjkl \
-d quay.io/kelee/ignition-maker-ubi:8.1.10
```

You can also place the activation token and/or license key in a file that is either integrated with Docker Secrets (via Docker Compose or Swarm) or simply bind-mounted into the container. Appending _FILE to the environment variables causes the value to be read in from the declared file location. If we have a file containing our activation token named activation-token, we can run the container like below:

```bash
podman run -p 8088:8088 \ 
--name my-ignition-maker --privileged \
-e GATEWAY_ADMIN_PASSWORD=password \
-e IGNITION_EDITION=maker \
-e IGNITION_LICENSE_KEY=ABCD_1234 \
-v /path/to/activation-token:/activation-token \
-e IGNITION_ACTIVATION_TOKEN_FILE=/activation-token \
-d quay.io/kelee/ignition-maker-ubi:8.1.10
```



