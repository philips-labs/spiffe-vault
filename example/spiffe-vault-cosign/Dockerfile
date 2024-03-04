FROM ghcr.io/philips-labs/spiffe-vault:v0.5.0
LABEL maintainer="marco.franssen@philips.com"
ENV DOCKER_CERT_PATH=/certs/client
COPY --from=docker:20.10.21-alpine3.16 /usr/local/bin/docker /usr/local/bin/docker
COPY --from=gcr.io/projectsigstore/cosign:v1.13.1 /ko-app/cosign /usr/local/bin/cosign
