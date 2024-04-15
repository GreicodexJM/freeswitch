# Makefile for building Docker images for greicodex/freeswitch

# Define variables for docker tags and Dockerfile paths
BASE_IMAGE_NAME=greicodex/freeswitch:alpine-latest-build
BINARY_IMAGE_NAME=greicodex/freeswitch
BASE_DOCKERFILE=docker/build/alpine-latest.dockerfile
BINARY_DOCKERFILE=docker/freeswitch.Dockerfile

# Default target
all: binary-image

# Target for building the base image
base-image: $(BASE_DOCKERFILE)
	@if [ -z "$$(docker images -q $(BASE_IMAGE_NAME))" ]; then \
		echo "Base image not found. Building base image..."; \
		docker build -t $(BASE_IMAGE_NAME) -f $(BASE_DOCKERFILE) .; \
	else \
		echo "Base image already exists."; \
	fi

# Target for building the binary image, depends on the base image
binary-image: base-image $(BINARY_DOCKERFILE)
	docker build -t $(BINARY_IMAGE_NAME) -f $(BINARY_DOCKERFILE) .

# Phony targets for clarity and to avoid conflicts with files of the same name
.PHONY: all base-image binary-image

