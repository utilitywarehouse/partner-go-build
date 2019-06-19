# partner-go-build

Base Docker image that contains all the necessary binaries for building Go services.

## Usage

We use [Quay](https://quay.io) to host the publically accessible image.

```
docker pull quay.io/utilitywarehouse/partner-go-build
```

Locally you can make sure you're using the same version, without the need to install the binary

```
docker run -t -v "$(PWD):/build" quay.io/utilitywarehouse/partner-go-build \
  protoc -I=pb \
  --gogoslick_out=Mgoogle/protobuf/any.proto=github.com/gogo/protobuf/types,Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,plugins=grpc,import_path=pb:pb \
  pb/*.proto
```

## Tools

| Name | Version | Binaries |
| --- | --- | --- |
| [docker](https://download.docker.com/linux/static/stable/x86_64/) | 18.09.5 | docker |
| [protoc](https://github.com/protocolbuffers/protobuf) | 3.7.0 | protoc |
| [golang/protobuf](https://github.com/golang/protobuf) | 1.3.1 | protoc-gen-go |
| [gogo/protobuf](https://github.com/gogo/protobuf) | 1.2.1 | protoc-gen-gogoslick |
| [envoyproxy/protoc-gen-validate](github.com/envoyproxy/protoc-gen-validate) | 0.0.14 | protoc-gen-validate |
| [mwitkow/protoc-gen-govalidators](github.com/mwitkow/go-proto-validators) | 1f388280e944c97cc59c75d8c84a704097d1f1d6 | protoc-gen-govalidators |
| [utilitywarehouse/protoc-gen-uwpartner](github.com/utilitywarehouse/protoc-gen-uwpartner) | de4552500027969912fd801dcc5269a153b3fffe | protoc-gen-uwpartner |
| [grpc-gateway/protoc-gen-grpc-gateway](github.com/grpc-ecosystem/grpc-gateway) |  1.9.0 | protoc-gen-grpc-gateway |
| [grpc-gateway/protoc-gen-swagger](github.com/grpc-ecosystem/grpc-gateway) |  1.9.0 | protoc-gen-swagger |
| [golang/mockgen](github.com/golang/mock) | 1.3.1 | mockgen |
| [golangci-lint](https://github.com/golangci/golangci-lint) | 1.17.1 | golangci-lint |

## Building

Quay will build each branch that is pushed to the repo, including master.

Each branch will be tagged so you can use PRs to test things you are working on. Master will also tag `latest`.

To keep a consistent set of tools across environments & builds, the binaries we use in the container are pinned.
If you update these versions make sure both readme & **ENV** values are kept in sync.
