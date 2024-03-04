FROM golang:1.22-alpine AS builder
RUN mkdir build
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN apk add --no-cache make git
RUN make build

FROM vault:1.13.3 AS vault-binary

FROM alpine:3.19.1 AS certs
RUN apk add --no-cache ca-certificates

FROM busybox:1.36.1
LABEL maintainer="marco.franssen@philips.com"
RUN mkdir -p /app
WORKDIR /app
ENV VAULT_ADDR=
COPY --from=certs /etc/ssl/certs /etc/ssl/certs
COPY --from=builder build/bin/spiffe-vault /usr/local/bin/spiffe-vault
COPY --from=vault-binary bin/vault /usr/local/bin/vault
ENTRYPOINT [ "/usr/local/bin/spiffe-vault" ]
