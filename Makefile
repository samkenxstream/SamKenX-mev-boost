VERSION ?= $(shell git describe --tags --always --dirty="-dev")
DOCKER_REPO := flashbots/mev-boost

.PHONY: all
all: build

.PHONY: v
v:
	@echo "${VERSION}"

.PHONY: build
build:
	go build -ldflags "-X main.version=${VERSION}" -v -o mev-boost ./cmd/mev-boost

.PHONY: build-testcli
build-testcli:
	go build -ldflags "-X main.version=${VERSION}" -v -o test-cli ./cmd/test-cli

.PHONY: test
test:
	go test ./...

.PHONY: test-race
test-race:
	go test -race ./...

.PHONY: lint
lint:
	revive -set_exit_status ./...
	go vet ./...
	staticcheck ./...

.PHONY: test-coverage
test-coverage:
	go test -race -v -covermode=atomic -coverprofile=coverage.out ./...
	go tool cover -func coverage.out

.PHONY: cover
cover:
	go test -coverprofile=coverage.out ./...
	go tool cover -func coverage.out
	unlink coverage.out

.PHONY: cover-html
cover-html:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out
	unlink coverage.out

.PHONY: run-mergemock-integration
run-mergemock-integration: build
	./scripts/run_mergemock_integration.sh

.PHONY: build-for-docker
build-for-docker:
	GOOS=linux go build -ldflags "-X main.version=${VERSION}" -v -o mev-boost ./cmd/mev-boost

.PHONY: docker-image
docker-image:
	DOCKER_BUILDKIT=1 docker build . -t mev-boost
	docker tag mev-boost:latest ${DOCKER_REPO}:${VERSION}
	docker tag mev-boost:latest ${DOCKER_REPO}:latest

.PHONY: docker-push
docker-push:
	docker push ${DOCKER_REPO}:${VERSION}
	docker push ${DOCKER_REPO}:latest

.PHONY: clean
clean:
	git clean -fdx
