FROM gcr.io/projectsigstore/cosign:v1.9.1 as cosign-bin

FROM docker:20.10.8 as docker-bin

FROM philipssoftware/spiffe-vault:v0.2.0
LABEL maintainer="marco.franssen@philips.com"
ENV DOCKER_CERT_PATH=/certs/client
COPY --from=docker-bin /usr/local/bin/docker /usr/local/bin/docker
COPY --from=cosign-bin /ko-app/cosign /usr/local/bin/cosign
