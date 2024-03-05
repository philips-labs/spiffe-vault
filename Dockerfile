ARG goversion=1.22
FROM --platform=${BUILDPLATFORM} golang:${goversion}-alpine AS base
RUN mkdir build
WORKDIR /build
RUN apk add --update --no-cache make git
COPY go.* ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .


FROM --platform=${BUILDPLATFORM} base AS builder
ARG TARGETPLATFORM
ARG TARGETARCH
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    make build

FROM --platform=${BUILDPLATFORM} vault:1.13.3 AS vault-binary

FROM --platform=${BUILDPLATFORM} alpine:3.19.1 AS certs
RUN apk add --update --no-cache ca-certificates

FROM busybox:1.36.1
ENTRYPOINT [ "/usr/local/bin/spiffe-vault" ]
ENV VAULT_ADDR=
LABEL maintainer="marco.franssen@philips.com"
RUN mkdir -p /app
WORKDIR /app
COPY --link --from=certs /etc/ssl/certs /etc/ssl/certs
COPY --link --from=builder build/bin/spiffe-vault /usr/local/bin/spiffe-vault
COPY --link --from=vault-binary bin/vault /usr/local/bin/vault
