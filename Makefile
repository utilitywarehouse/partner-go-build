
ifeq ("$(wildcard project)","")
$(error project directory doesn't exist)
endif

ifneq ("$(wildcard project/app.mk)","")
include project/app.mk
endif

# --------------------------------------------------------------------------------------------------
# Variables
# --------------------------------------------------------------------------------------------------

ifndef APP_NAME
$(error APP_NAME is not set in the app.mk file)
endif

ifndef APP_DESCRIPTION
$(error APP_DESCRIPTION is not set in the app.mk file)
endif

GIT_SUMMARY := $(shell cd project && git describe --tags --dirty --always)
GIT_BRANCH := $(shell cd project && git rev-parse --abbrev-ref HEAD)
BUILD_STAMP := $(shell date -u '+%Y-%m-%dT%H:%M:%S%z')

DOCKER_REGISTRY ?= registry.uw.systems
DOCKER_NAMESPACE ?= partner
MAIN_IMAGE_NAME := $(subst $(DOCKER_NAMESPACE)-,,$(APP_NAME))
DOCKER_BASE_NAME ?= $(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)

ifeq ($(GIT_BRANCH), master)
    DOCKER_TAG := latest
else
    DOCKER_TAG := $(GIT_BRANCH)
endif

LDFLAGS := -ldflags '-s \
	-X "github.com/utilitywarehouse/partner-pkg/meta.ApplicationName=$(APP_NAME)" \
	-X "github.com/utilitywarehouse/partner-pkg/meta.ApplicationDescription=$(APP_DESCRIPTION)" \
	-X "github.com/utilitywarehouse/partner-pkg/meta.GitSummary=$(GIT_SUMMARY)" \
	-X "github.com/utilitywarehouse/partner-pkg/meta.GitBranch=$(GIT_BRANCH)" \
	-X "github.com/utilitywarehouse/partner-pkg/meta.BuildStamp=$(BUILD_STAMP)"'

# --------------------------------------------------------------------------------------------------
# Setup Tasks
# --------------------------------------------------------------------------------------------------

install: ## install dependencies and redact github token
	cd project && go mod download 2>&1 | sed -e "s/[[:alnum:]]*:x-oauth-basic/redacted/"

test: ## run tests on package and all subpackages
	cd project && go test $(LDFLAGS) -v -race -tags integration ./...

lint: ## run the linter
	cd project && golangci-lint run --deadline=2m

# --------------------------------------------------------------------------------------------------
# Build Tasks
# --------------------------------------------------------------------------------------------------

build-app:
ifneq ("$(wildcard project/main.go)","")
	cd project && CGO_ENABLED=0 go build $(LDFLAGS) -o ../bin/$(MAIN_IMAGE_NAME) -a .
endif

cmd_sources = $(dir $(wildcard ./project/cmd/*/main.go))
cmds = $(foreach source,$(cmd_sources),$(patsubst %/,%,$(subst ./project/cmd/,./bin/$(MAIN_IMAGE_NAME)-,$(source))))

define go-build
	cd ./$< && CGO_ENABLED=0 go build $(LDFLAGS) -o ./../../../$@ -a .
endef

./bin/$(MAIN_IMAGE_NAME)-%: ./project/cmd/% ## build individual command
	$(go-build)

build-commands: $(cmds) ## build all commands

build-all: build-app build-commands

# --------------------------------------------------------------------------------------------------
# Docker Build Tasks
# --------------------------------------------------------------------------------------------------

docker_commands = $(foreach source,$(cmd_sources),$(subst /,,$(subst ./project/cmd/,docker-build-cmd-$(MAIN_IMAGE_NAME)-,$(source))))

define docker-build
	docker build -f Dockerfile.project -t $(DOCKER_BASE_NAME)/$(image_name):$(CIRCLE_SHA1) . --build-arg EXECUTABLE=$(image_name)
endef

docker-build-app: ## build docker image for main app
ifneq ("$(wildcard project/main.go)","")
	docker build -f Dockerfile.project -t $(DOCKER_BASE_NAME)/$(MAIN_IMAGE_NAME):$(CIRCLE_SHA1) . --build-arg EXECUTABLE=$(MAIN_IMAGE_NAME)
endif

docker-build-cmd-%: image_name = $(subst docker-build-cmd-,,$@)
docker-build-cmd-%: ./bin/% ## build docker image for one command
	$(docker-build)

docker-build-commands: $(docker_commands)

ensure-static: ## ensures that a static folder exists in the project
	mkdir -p project/static

docker-build-all: ensure-static build-all docker-build-app docker-build-commands

# --------------------------------------------------------------------------------------------------
# Docker Push Tasks
# --------------------------------------------------------------------------------------------------

image_sources = $(sort $(shell find ./bin -mindepth 1 -maxdepth 1 -exec basename {} \;))
images = $(foreach image,$(image_sources),docker-push-image-$(image))

define docker-push-image
	docker tag $(DOCKER_BASE_NAME)/$(image_name):$(CIRCLE_SHA1) $(DOCKER_BASE_NAME)/$(image_name):$(DOCKER_TAG)
	docker push $(DOCKER_BASE_NAME)/$(image_name)
endef

docker-push-image-%: image_name = $(subst docker-push-image-,,$@)
docker-push-image-%: ## load tag and push a single docker image
	$(docker-push-image)

docker-login:
	@docker login -u $(DOCKER_ID) -p $(DOCKER_PASSWORD) $(DOCKER_REGISTRY)

docker-push-all: docker-login $(images)
