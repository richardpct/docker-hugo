.DEFAULT_GOAL := help
AWK           := awk
DOCKER        = /usr/local/bin/docker
VPATH         := dockerfile
BUILD         := .build
CONTAINER     := hugo
IMAGE         := richardpct/$(CONTAINER)
FQDN          := richardpct.github.io
VOL_SOURCE    ?= $(HOME)/github/hugo-richardpct.github.io/source
VOL_OUTPUT    ?= $(HOME)/github/$(FQDN)
CONFIG_TOML   := $(VOL_SOURCE)/$(FQDN)/config.toml
GOHUGO_THEME  := https://github.com/goodroot/hugo-classic
THEME         := hugo-classic

# If DOCKER does not exist then looks for in the PATH variable
ifeq "$(wildcard $(DOCKER))" ""
  DOCKER_FOUND := $(shell which docker)
  DOCKER = $(if $(DOCKER_FOUND),$(DOCKER_FOUND),$(error docker is not found))
endif

# Check if Docker is running
ifneq "$(MAKECMDGOALS)" "$(filter $(MAKECMDGOALS), help)"
  ifneq "$(shell $(DOCKER) version > /dev/null && echo running)" "running"
    $(error Docker is not running)
  endif
endif

# Check if the PAGE variable is defined when using the new target
ifeq "$(MAKECMDGOALS)" "new"
  ifndef PAGE
    $(error PAGE variable is not defined, run the following command: make new PAGE=post/new.md)
  endif
endif

# $(call docker-image-rm)
define docker-image-rm
  if $(DOCKER) image inspect $(IMAGE) > /dev/null 2>&1; then \
    $(DOCKER) image rm $(IMAGE); \
    rm -f $(BUILD); \
  fi
endef

# $(call docker-container-stop)
define docker-container-stop
  if $(DOCKER) container inspect $(CONTAINER) > /dev/null 2>&1; then \
    $(DOCKER) container stop $(CONTAINER); \
  fi
endef

.PHONY: help
help: ## Show help
	@echo "Usage: make [VOL_SOURCE=source][VOL_OUTPUT=output] TARGET\n"
	@echo "Targets:"
	@$(AWK) -F ":.* ##" '/^[^#].*:.*##/{printf "%-13s%s\n", $$1, $$2}' \
	$(MAKEFILE_LIST) \
	| grep -v AWK

.PHONY: shell
shell: run ## Get a shell into the container
	$(DOCKER) container exec -it $(CONTAINER) /bin/sh

.PHONY: static
static: run ## Build static pages
	$(DOCKER) container exec $(CONTAINER) hugo -d ../../output
	@echo building static pages in $(VOL_OUTPUT)

.PHONY: new
new: run $(VOL_SOURCE)/$(FQDN)/content/$(PAGE) ## Add new page: make new PAGE=post/new.md

$(VOL_SOURCE)/$(FQDN)/content/$(PAGE):
	$(DOCKER) container exec $(CONTAINER) hugo new $(PAGE)
	@echo building new $(PAGE) page

.PHONY: run
run: init ## Run the container: make [VOL_SOURCE=source][VOL_SOURCE=output] run
	if ! $(DOCKER) container inspect $(CONTAINER) > /dev/null 2>&1; then \
	  $(DOCKER) container run --rm -d \
	  -v $(VOL_SOURCE):/var/hugo \
	  -v $(VOL_OUTPUT):/var/output \
	  -p 1313:1313 \
	  --name $(CONTAINER) \
	  $(IMAGE); \
	fi

	@echo you can access your blog at http://localhost:1313

.PHONY: init
init: $(BUILD) $(CONFIG_TOML) ## Initialize the configuration

$(CONFIG_TOML):
	$(DOCKER) container run --rm \
	-v $(VOL_SOURCE):/var/hugo \
	--name $(CONTAINER) \
	$(IMAGE) \
	hugo new site /var/hugo/richardpct.github.io

	git clone $(GOHUGO_THEME) $(VOL_SOURCE)/$(FQDN)/themes/$(THEME)
	rm -rf $(VOL_SOURCE)/$(FQDN)/themes/$(THEME)/.git
	rm -f $(VOL_SOURCE)/$(FQDN)/themes/$(THEME)/.gitignore
	cp -r $(VOL_SOURCE)/$(FQDN)/themes/$(THEME)/exampleSite/content/* \
	  $(VOL_SOURCE)/$(FQDN)/content/
	cp -r $(VOL_SOURCE)/$(FQDN)/themes/$(THEME)/exampleSite/static/* \
	  $(VOL_SOURCE)/$(FQDN)/static/
	cp $(VOL_SOURCE)/$(FQDN)/themes/$(THEME)/exampleSite/config.toml \
	  $(VOL_SOURCE)/$(FQDN)/

.PHONY: build
build: $(BUILD) ## Build the image from the Dockerfile

$(BUILD): Dockerfile
	$(call docker-container-stop)
	$(call docker-image-rm)

	cd dockerfile && \
	$(DOCKER) build -t $(IMAGE) .
	@touch $@

.PHONY: clean
clean: stop ## Delete the image
	$(call docker-image-rm)

.PHONY: stop
stop: ## Stop the container
	$(call docker-container-stop)
