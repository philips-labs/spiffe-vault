FROM golang:1.17-alpine as builder
RUN mkdir build
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN apk add --no-cache make git
RUN make build

FROM busybox
LABEL maintainer="marco.franssen@philips.com"
RUN mkdir -p /app
WORKDIR /app
ENV VAULT_ADDR=
COPY --from=builder build/bin/spiffe-vault .
ENTRYPOINT [ "/app/spiffe-vault" ]
