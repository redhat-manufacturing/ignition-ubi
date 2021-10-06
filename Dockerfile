# Ignition Version
ARG IGNITION_VERSION="8.1.10"
# IGNITION_RC_VERSION should be something like `8.1.8-rc1` when applicable, otherwise blank
ARG IGNITION_RC_VERSION=""

# Default Build Edition - STABLE or NIGHTLY
ARG BUILD_EDITION="STABLE"

FROM registry.access.redhat.com/ubi8/ubi:latest AS downloader
LABEL maintainer "Ken Lee <kelee@redhat.com>"
ARG IGNITION_VERSION
ARG BUILD_EDITION

# Install some prerequisite packages
RUN dnf update -y && dnf install -y wget unzip && dnf -y clean all

# Ignition Downloader Parameters
ARG IGNITION_STABLE_AMD64_DOWNLOAD_URL="https://files.inductiveautomation.com/release/ia/8.1.10/20210908-1153/Ignition-linux-64-8.1.10.zip"
ARG IGNITION_STABLE_AMD64_DOWNLOAD_SHA256="736ff3696308df1bdf4918f6049dedacf61cca9798230a25908e72f839816e77"
ARG IGNITION_RC_AMD64_DOWNLOAD_URL=""
ARG IGNITION_RC_AMD64_DOWNLOAD_SHA256=""
ARG IGNITION_NIGHTLY_AMD64_DOWNLOAD_URL="https://files.inductiveautomation.com/builds/nightly/8.1.11-SNAPSHOT/Ignition-linux-64-8.1.11-SNAPSHOT.zip"
ARG IGNITION_NIGHTLY_AMD64_DOWNLOAD_SHA256="notused"
ARG IGNITION_AMD64_JRE_SUFFIX="nix"

ARG IGNITION_STABLE_ARMHF_DOWNLOAD_URL="https://files.inductiveautomation.com/release/ia/8.1.10/20210908-1153/Ignition-linux-armhf-8.1.10.zip"
ARG IGNITION_STABLE_ARMHF_DOWNLOAD_SHA256="44c3cd44ace95a1a6ecb2d88d3f91c7a111b05f1abb4b0ffb53fea3152bb6454"
ARG IGNITION_RC_ARMHF_DOWNLOAD_URL=""
ARG IGNITION_RC_ARMHF_DOWNLOAD_SHA256=""
ARG IGNITION_NIGHTLY_ARMHF_DOWNLOAD_URL="https://files.inductiveautomation.com/builds/nightly/8.1.11-SNAPSHOT/Ignition-linux-armhf-8.1.11-SNAPSHOT.zip"
ARG IGNITION_NIGHTLY_ARMHF_DOWNLOAD_SHA256="notused"
ARG IGNITION_ARMHF_JRE_SUFFIX="arm32hf"
ARG IGNITION_STABLE_ARM64_DOWNLOAD_URL="https://files.inductiveautomation.com/release/ia/8.1.10/20210908-1153/Ignition-linux-aarch64-8.1.10.zip"
ARG IGNITION_STABLE_ARM64_DOWNLOAD_SHA256="400d4ed1071bc8b7341e50510d2205e0f95770c6762573b8cb769af98583346b"
ARG IGNITION_RC_ARM64_DOWNLOAD_URL=""
ARG IGNITION_RC_ARM64_DOWNLOAD_SHA256=""
ARG IGNITION_NIGHTLY_ARM64_DOWNLOAD_URL="https://files.inductiveautomation.com/builds/nightly/8.1.11-SNAPSHOT/Ignition-linux-aarch64-8.1.11-SNAPSHOT.zip"
ARG IGNITION_NIGHTLY_ARM64_DOWNLOAD_SHA256="notused"
ARG IGNITION_ARM64_JRE_SUFFIX="aarch64"

# gosu Download Parameters
ARG GOSU_VERSION="1.14"
ARG GOSU_AMD64_DOWNLOAD_URL="https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64"
ARG GOSU_AMD64_DOWNLOAD_SHA256="bd8be776e97ec2b911190a82d9ab3fa6c013ae6d3121eea3d0bfd5c82a0eaf8c"
ARG GOSU_ARMHF_DOWNLOAD_URL="https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-armhf"
ARG GOSU_ARMHF_DOWNLOAD_SHA256="abb1489357358b443789571d52b5410258ddaca525ee7ac3ba0dd91d34484589"
ARG GOSU_ARM64_DOWNLOAD_URL="https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-arm64"
ARG GOSU_ARM64_DOWNLOAD_SHA256="73244a858f5514a927a0f2510d533b4b57169b64d2aa3f9d98d92a7a7df80cea"

# Retrieve Ignition Installer and Perform Ignition Installation
ENV INSTALLER_PATH /root
ENV INSTALLER_NAME "ignition-install.zip"
WORKDIR ${INSTALLER_PATH}

# Set to Bash Shell Execution instead of /bin/sh
SHELL [ "/bin/bash", "-c" ]

# Download Installation Zip File based on Detected Architecture
RUN set -exo pipefail; \
    dpkg_arch="$(echo amd64 | awk '{print toupper($0)}')";    \
    download_url_env="IGNITION_${BUILD_EDITION}_${dpkg_arch}_DOWNLOAD_URL"; \
    download_sha256_env="IGNITION_${BUILD_EDITION}_${dpkg_arch}_DOWNLOAD_SHA256"; \
    if [ -n "${!download_url_env}" ] && [ -n "${!download_sha256_env}" ]; then \
        wget -q --ca-certificate=/etc/ssl/certs/ca-certificates.crt --referer https://inductiveautomation.com/* -O "${INSTALLER_NAME}" "${!download_url_env}" && \
        if [[ ${BUILD_EDITION} != *"NIGHTLY"* ]]; then echo "${!download_sha256_env}" "${INSTALLER_NAME}" | sha256sum -c -; fi ; \
    else \
        echo "Architecture ${dpkg_arch} download targets for Ignition not defined, aborting build"; \
        exit 1; \
    fi

# Download gosu based on Detected Architecture
RUN set -exo pipefail; \
    dpkg_arch="$(echo amd64 | awk '{print toupper($0)}')";    \
    download_url_env="GOSU_${dpkg_arch}_DOWNLOAD_URL"; \
    download_sha256_env="GOSU_${dpkg_arch}_DOWNLOAD_SHA256"; \
    if [[ -n "${!download_url_env}" ]] && [[ -n "${!download_sha256_env}" ]]; then \
        wget -q --ca-certificate=/etc/ssl/certs/ca-certificates.crt -O "gosu" "${!download_url_env}" && \
        echo "${!download_sha256_env}" "gosu" | sha256sum -c -; \
    else \
        echo "Architecture ${dpkg_arch} download targets for gosu not defined, aborting build"; \
        exit 1; \
    fi; \
    chmod a+x "gosu"

# Extract Installation Zip File
RUN mkdir ignition && \
    unzip -q ${INSTALLER_NAME} -d ignition/ && \
    chmod +x ignition/ignition-gateway ignition/*.sh

# Change to Ignition folder
WORKDIR ${INSTALLER_PATH}/ignition

# Modify ignition.sh file
RUN sed -E -i 's/^(PIDFILE_CHECK_PID=true)/#\1/' ignition.sh

# Add jre-tmp folder in base ignition location
RUN mkdir -p jre-tmp

# Stage data, temp, logs and user-lib in var folders
RUN mkdir -p /var/lib/ignition && \
    mv data /var/lib/ignition/ && \
    mv user-lib /var/lib/ignition/ && \
    mv logs /var/log/ignition && \
    ln -s /var/lib/ignition/data data && \
    ln -s /var/lib/ignition/user-lib user-lib && \
    ln -s /var/log/ignition logs && \
    ln -s /var/lib/ignition/data/metro-keystore webserver/metro-keystore

# # RUNTIME IMAGE
# FROM registry.access.redhat.com/ubi8/ubi:latest AS final
FROM downloader as final
ARG IGNITION_VERSION
ARG BUILD_EDITION

# Capture BUILD_EDITION into environment variable
ENV BUILD_EDITION ${BUILD_EDITION:-FULL}

# Install some prerequisite packages
RUN dnf update -y && \
    dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y && \
    dnf install -y curl gettext procps pwgen zip unzip fontconfig jq tini sqlite dejavu-sans-fonts glibc-locale-source glibc-langpack-en java-11-openjdk && \
    dnf -y clean all && \
    localedef -c -f UTF-8 -i en_US en_US.UTF-8

# Setup Install Targets and Locale Settings
ENV IGNITION_LIB_LOCATION="/var/lib/ignition/" \
    IGNITION_LOG_LOCATION="/var/log/ignition/" \
    IGNITION_INSTALL_LOCATION="/usr/local/share/ignition" \
    IGNITION_INSTALL_USERHOME="/home/ignition" \
    LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Build Arguments for UID/GID
ARG IGNITION_UID
ARG IGNITION_GID
ENV IGNITION_UID=1001 \
    IGNITION_GID=0

# Setup dedicated user, map file permissions, and set execution flags
RUN mkdir ${IGNITION_INSTALL_USERHOME} && \
    # (groupadd -r ignition -g ${IGNITION_GID}) && \
    (useradd -r -d ${IGNITION_INSTALL_USERHOME} -u ${IGNITION_UID} -g ${IGNITION_GID} ignition) && \
    chown ${IGNITION_UID}:${IGNITION_GID} ${IGNITION_INSTALL_USERHOME} && \
    mkdir -p /data && chown ${IGNITION_UID}:${IGNITION_GID} /data

# Copy Ignition Installation from Build Image
COPY --chown=${IGNITION_UID}:${IGNITION_GID} --from=downloader /root/ignition ${IGNITION_INSTALL_LOCATION}
COPY --chown=${IGNITION_UID}:${IGNITION_GID} --from=downloader /var/lib/ignition /var/lib/ignition
COPY --chown=${IGNITION_UID}:${IGNITION_GID} --from=downloader /var/log/ignition /var/log/ignition
COPY --from=downloader /root/gosu /usr/local/bin/
RUN ln -s /dev/stdout /var/log/ignition/wrapper.log

# Declare Healthcheck
HEALTHCHECK --interval=10s --start-period=60s --timeout=3s \
    CMD curl --max-time 3 -f http://localhost:${GATEWAY_HTTP_PORT:-8088}/StatusPing 2>&1 | grep RUNNING

# Setup Port Expose
EXPOSE 8088

# Launch Ignition
USER root
WORKDIR ${IGNITION_INSTALL_LOCATION}

# Update path to include embedded java install location
ENV PATH="${IGNITION_INSTALL_LOCATION}/lib/runtime/jre/bin:${PATH}"

# Copy in Entrypoint and helper scripts
COPY *.sh /usr/local/bin/

STOPSIGNAL SIGINT

USER 1001

# Prepare Execution Settings
ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
CMD [ "./ignition-gateway" ]
