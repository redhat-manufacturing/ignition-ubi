# Overview

For additional documentation, please see the following: 

https://github.com/thirdgen88/ignition-docker/tree/master/docs

Much of what you see here is based on the contributions found in the aformentioned github repository.

# Ignition 8.1.x Docker Image

If you're on Linux/macOS, you can build this image using the supplied Makefile to automate the docker image build.  There are a few build targets defined for your convenience, as outlined below.  

## Single Architecture Local Builds

To build both the _FULL_ and _EDGE_ editions locally (with a custom tag) against your native architecture:

    $ make build BASE_IMAGE_NAME=custom/ignition

This will create images `custom/ignition` with tags `8.1.x`, and `8.1` (based on the current version).

You can also specify a registry target for the `BASE_IMAGE_NAME` so you can then push those images to your custom Docker image registry:

    $ make build BASE_IMAGE_NAME=localhost:5000/custom/ignition
    $ make push-registry

... which will build and push images to the registry running at `localhost:5000`.

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
