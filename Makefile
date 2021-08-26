GIT_TAG ?= dirty-tag
GIT_VERSION ?= $(shell git describe --tags --always --dirty)
GIT_HASH ?= $(shell git rev-parse HEAD)
DATE_FMT = +'%Y-%m-%dT%H:%M:%SZ'
SOURCE_DATE_EPOCH ?= $(shell git log -1 --pretty=%ct)
ifdef SOURCE_DATE_EPOCH
    BUILD_DATE ?= $(shell date -u -d "@$(SOURCE_DATE_EPOCH)" "$(DATE_FMT)" 2>/dev/null || date -u -r "$(SOURCE_DATE_EPOCH)" "$(DATE_FMT)" 2>/dev/null || date -u "$(DATE_FMT)")
else
    BUILD_DATE ?= $(shell date "$(DATE_FMT)")
endif
GIT_TREESTATE = "clean"
DIFF = $(shell git diff --quiet >/dev/null 2>&1; if [ $$? -eq 1 ]; then echo "1"; fi)
ifeq ($(DIFF), 1)
    GIT_TREESTATE = "dirty"
endif

PKG=github.com/philips-labs/spiffe-vault/cmd/spiffe-vault/cli
LDFLAGS="-X $(PKG).GitVersion=$(GIT_VERSION) -X $(PKG).gitCommit=$(GIT_HASH) -X $(PKG).gitTreeState=$(GIT_TREESTATE) -X $(PKG).buildDate=$(BUILD_DATE)"

GO_BUILD_FLAGS := -trimpath -ldflags $(LDFLAGS)
COMMANDS       := spiffe-vault

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

FORCE: ;

bin/%: cmd/% FORCE
	CGO_ENABLED=0 go build $(GO_BUILD_FLAGS) -o $@ ./$<

.PHONY: download
download: ## download dependencies via go mod
	go mod download

.PHONY: build
build: $(addprefix bin/,$(COMMANDS)) ## builds binaries

.PHONY: image
image: ## build the binary in a docker image
	docker build \
		-t "philipssoftware/spiffe-vault:$(GIT_TAG)" \
		-t "philipssoftware/spiffe-vault:$(GIT_HASH)" .

.PHONY: snapshot-release
snapshot-release: ## creates a snapshot release using goreleaser
	LDFLAGS=$(LDFLAGS) GIT_TAG=$(GIT_TAG) GIT_HASH=$(GIT_HASH) goreleaser release --snapshot --rm-dist

.PHONY: release
release: ## creates a release using goreleaser
	LDFLAGS=$(LDFLAGS) GIT_TAG=$(GIT_TAG) GIT_HASH=$(GIT_HASH) goreleaser release

release-vars: ## print the release variables for goreleaser
	@echo export LDFLAGS=\"$(LDFLAGS)\"
	@echo export GIT_TAG=$(GIT_TAG)
	@echo export GIT_HASH=$(GIT_HASH)
