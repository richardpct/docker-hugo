.PHONY: build init run exec new stop generate rm

.DEFAULT_GOAL := run
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
DOCKER_EXISTS := $(shell which docker)

ifndef DOCKER_EXISTS
  $(error docker is not found)
endif

# $(call docker-image-rm)
define docker-image-rm
  if docker image inspect $(IMAGE) > /dev/null 2>&1 ; then \
    docker image rm $(IMAGE); \
    rm -f $(BUILD); \
  fi
endef

# $(call docker-container-stop)
define docker-container-stop
  if docker container inspect $(CONTAINER) > /dev/null 2>&1 ; then \
    docker container stop $(CONTAINER); \
  fi
endef

build: $(BUILD)

.build: Dockerfile
	$(call docker-container-stop)
	$(call docker-image-rm)

	cd dockerfile && \
	docker build -t $(IMAGE) .
	@touch $@

init: $(BUILD)
ifeq "$(wildcard $(CONFIG_TOML))" ""
	docker container run --rm \
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
endif

run: init
	if ! docker container inspect $(CONTAINER) > /dev/null 2>&1 ; then \
	  docker container run --rm -d \
	  -v $(VOL_SOURCE):/var/hugo \
	  -v $(VOL_OUTPUT):/var/output \
	  -p 1313:1313 \
	  --name $(CONTAINER) \
	  $(IMAGE); \
	fi

	@echo you can access your blog at http://localhost:1313

exec: run
	docker container exec -it $(CONTAINER) /bin/sh

generate: run
	docker container exec $(CONTAINER) hugo -d ../../output
	@echo building static pages in $(VOL_OUTPUT)

new: run
ifndef PAGE
	$(error PAGE variable is not defined, run the followin command: make new PAGE=new.md)
endif

ifeq "$(wildcard $(VOL_SOURCE)/$(FQDN)/content/$(PAGE))" ""
	docker container exec $(CONTAINER) hugo new $(PAGE)
	@echo building new $(PAGE)
else
	@echo $(PAGE) already exists
endif

stop:
	$(call docker-container-stop)

rm: stop
	$(call docker-image-rm)
