
# Required for globs to work correctly
SHELL=/usr/bin/env bash

# go option
GO        ?= go
#PKG       := $(shell glide novendor)
TAGS      :=
TESTS     := .
TESTFLAGS :=
LDFLAGS   := -w -s
GOFLAGS   :=
BINDIR    := $(CURDIR)/bin
BINARIES  := node
IMAGE     := sample-serf


.PHONY: all
all: build

.PHONY: build
build: docker-build

.PHONY: docker-binary
docker-binary: BINDIR = ./build/docker
docker-binary: GOFLAGS += -a -installsuffix cgo
docker-binary:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 $(GO) build -o $(BINDIR)/node $(GOFLAGS) -tags '$(TAGS)' -ldflags '$(LDFLAGS)' ./cmd/node


.PHONY: docker-build
docker-build: docker-binary
docker-build: BINDIR = ./build/docker
docker-build:
	docker build --rm -t ${IMAGE} ${BINDIR}


.PHONY: deploy
deploy:
