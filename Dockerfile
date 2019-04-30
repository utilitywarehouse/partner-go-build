FROM golang:1.12.4

ENV DOCKER_VERSION="18.09.5" \
    PROTOBUF_VERSION="3.7.0" \
    GOLANG_PROTOBUF_VERSION="1.3.1" \
    GOGO_PROTOBUF_VERSION="1.2.1" \
    VALIDATE_PROTOBUF_VERSION="0.0.14" \
    VALIDATORS_PROTOBUF_VERSION="1f388280e944c97cc59c75d8c84a704097d1f1d6" \
    UWPARTNER_PROTOBUF_VERSION="de4552500027969912fd801dcc5269a153b3fffe" \
    GOLANGCI_LINT_VERSION="1.16.0"

## Dependencies
RUN apt-get update \
    && apt-get install -y ca-certificates curl unzip tar

## `docker` binary
RUN set -ex \
    && curl  -sSL --retry 3 https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz -o /tmp/docker.tgz \
    && ls -lha /tmp/docker.tgz \
    && tar -xz -C /tmp -f /tmp/docker.tgz \
    && mv /tmp/docker/* /usr/local/bin \
    && rm -rf /tmp/docker /tmp/docker.tgz

## `protoc` binary
RUN mkdir -p /tmp/protoc && cd /tmp/protoc \
    && curl -sSL --retry 3 https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip -o protoc.zip \
    && unzip protoc.zip \
    && mv /tmp/protoc/bin/protoc* /usr/local/bin \
    && mv /tmp/protoc/include/* /usr/local/include \
    && rm -rf /tmp/protoc

## `protoc-gen-go` binaries
## `protoc-gen-gogoslick` binaries
RUN GO111MODULE=on go get \
    github.com/golang/protobuf/protoc-gen-go@v${GOLANG_PROTOBUF_VERSION} \
    github.com/gogo/protobuf/protoc-gen-gogoslick@v${GOGO_PROTOBUF_VERSION} \
    && mv /go/bin/protoc-gen-* /usr/local/bin/

## `protoc-gen-validate` binary
## `protoc-gen-govalidators` binary
RUN GO111MODULE=on go get \
    github.com/envoyproxy/protoc-gen-validate@v${VALIDATE_PROTOBUF_VERSION} \
    github.com/mwitkow/go-proto-validators/protoc-gen-govalidators@${VALIDATORS_PROTOBUF_VERSION} \
    && mv /go/bin/protoc-gen-* /usr/local/bin/

## `protoc-gen-uwpartner` binary
RUN GO111MODULE=on go get \
    github.com/utilitywarehouse/protoc-gen-uwpartner@${UWPARTNER_PROTOBUF_VERSION} \
    && mv /go/bin/protoc-gen-* /usr/local/bin/

## `golangci-lint` binary
# Golangci Lint
RUN mkdir -p /tmp/golangci-lint && cd /tmp/golangci-lint \
    && curl -sSL --retry 3 https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION}-linux-amd64.tar.gz -o golangci-lint.tar.gz \
    && tar -xvf golangci-lint.tar.gz \
    && mv /tmp/golangci-lint/golangci-lint-${GOLANGCI_LINT_VERSION}-linux-amd64/golangci-lint /usr/local/bin \
    && rm -rf /tmp/golangci-lint
ADD ./.golangci.yml /

## Cleanup Go caches used during install/build
RUN go clean -cache -testcache -modcache

# Copy in makefile and project docker image
WORKDIR /build
ADD ./Makefile .
ADD ./Dockerfile.project .
RUN mkdir project && mkdir bin
