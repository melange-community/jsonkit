project_name = jsonkit

DUNE = opam exec -- dune

.DEFAULT_GOAL := help

.PHONY: help
help: ## Print this help message
	@echo "List of available make commands";
	@echo "";
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}';
	@echo "";

.PHONY: create-switch
create-switch: ## Create opam switch
	opam switch create . 5.4.0 -y --deps-only

.PHONY: init
init: create-switch install hooks ## Configure everything to develop this repository in local

.PHONY: hooks
hooks: ## Install the repo git hooks (enforce jsonkit@X.Y.Z tag naming)
	git config core.hooksPath .githooks

.PHONY: tag
tag: ## Create a release tag: make tag version=X.Y.Z creates jsonkit.X.Y.Z
	@test -n "$(version)" || { echo "usage: make tag version=X.Y.Z"; exit 1; }
	ALLOW_TAG_CREATION=true git tag jsonkit.$(version)
	@echo "Created tag jsonkit.$(version). Push it with: git push origin jsonkit.$(version)"

github_repo = melange-community/$(project_name)
release_packages = jsonkit jsonkit-melange
release_tag = $(shell git tag --list '$(project_name).*' --sort=-v:refname | head -1)
release_version = $(patsubst $(project_name).%,%,$(release_tag))

.PHONY: release
release: ## Submit the latest jsonkit.X.Y.Z tag to opam-repository
	@test -n "$(release_tag)" || { echo "no $(project_name).* tag found; create one with: make tag version=X.Y.Z"; exit 1; }
	@git ls-remote --exit-code --tags origin refs/tags/$(release_tag) >/dev/null || { echo "tag $(release_tag) is not pushed; run: git push origin $(release_tag)"; exit 1; }
	opam publish --tag $(release_tag) -v $(release_version) \
	  https://github.com/$(github_repo)/archive/refs/tags/$(release_tag).tar.gz \
	  $(release_packages)

.PHONY: install
install: ## Install development dependencies
	yarn
	opam update
	opam install -y . --deps-only --with-test --with-dev-setup
	opam exec -- opam-check-npm-deps

.PHONY: build
build: ## Build the project
	$(DUNE) build @test @examples

.PHONY: build_verbose
build_verbose: ## Build the project
	$(DUNE) build --verbose @test

.PHONY: clean
clean: ## Clean build artifacts and other generated files
	$(DUNE) clean

.PHONY: format
format: ## Format the codebase with ocamlformat
	$(DUNE) build @fmt --auto-promote

.PHONY: format-check
format-check: ## Checks if format is correct
	$(DUNE) build @fmt

.PHONY: watch
watch: ## Watch for the filesystem and rebuild on every change
	$(DUNE) build --watch @test

.PHONY: test
test: ## Run the tests
	$(DUNE) build @runtest --no-buffer

ocaml54_switch = jsonkit-54

.PHONY: test-labeled-tuples
test-labeled-tuples: ## Run the labeled tuples tests (needs an OCaml >= 5.4 switch, override with ocaml54_switch=...)
	opam exec --switch $(ocaml54_switch) -- dune build @labeled_tuples --auto-promote

.PHONY: test-watch
test-watch: ## Run the tests and watch for changes
	$(DUNE) build -w @runtest

.PHONY: run-examples
run-examples: ## Run the examples
	$(DUNE) build @run-examples
