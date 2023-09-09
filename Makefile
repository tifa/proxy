.DEFAULT_GOAL := start

ACTIVATE = . venv/bin/activate;
ASSETS = $(shell find assets -type f -name '*')

COL_WIDTH = 15
FORMAT_YELLOW = 33
FORMAT_BOLD_YELLOW = \e[1;$(FORMAT_YELLOW)m
FORMAT_END = \e[0m
FORMAT_UNDERLINE = \e[4m

include .env

define usage
	@printf "Usage: make target\n\n"
	@printf "$(FORMAT_UNDERLINE)target$(FORMAT_END):\n"
	@grep -E "^[A-Za-z0-9_ -]*:.*#" $< | while read -r l; do printf "  $(FORMAT_BOLD_YELLOW)%-$(COL_WIDTH)s$(FORMAT_END)$$(echo $$l | cut -f2- -d'#')\n" $$(echo $$l | cut -f1 -d':'); done
endef

.git/hooks/pre-commit:
	$(ACTIVATE) pre-commit install
	@touch $@

venv: venv/.touchfile .git/hooks/pre-commit
venv/.touchfile: requirements.txt
	test -d venv || virtualenv venv
	$(ACTIVATE) pip install -Ur requirements.txt
	@touch $@

build: venv/.build_touchfile
venv/.build_touchfile: Dockerfile $(ASSETS)
	docker build -t $(PROJECT_NAME) .
	@touch $@

.PHONY: help
help: Makefile  # Print this message
	$(call usage)

.PHONY: start
start: venv cert build network  # Start proxy
	HOSTNAME=$(PROXY_HOST) docker compose up -d

.PHONY: restart
restart: stop start  # Restart proxy

.PHONY: stop
stop:  # Stop proxy
	docker compose down --remove-orphans
	$(MAKE) stop-network

.PHONY: cert
cert: cert-$(ENVIRONMENT)  # Generate certificate

.PHONY: cert-prod
cert-prod:

.PHONY: cert-local
cert-local:
	$(eval DNS_HOSTNAMES=$(shell echo $(HOSTNAMES) | awk 'BEGIN{OFS=", "; RS=","; prefix="DNS:"} {$$1=prefix $$1} {printf("%s%s", NR==1 ? "" : OFS, $$1)} END {printf("\n")}'))
	$(eval FIRST_HOSTNAME=$(shell echo $(HOSTNAMES) | cut -d',' -f1))
	@DNS_HOSTNAMES="$(DNS_HOSTNAMES)" \
		FIRST_HOSTNAME="$(FIRST_HOSTNAME)" \
		envsubst < ./assets/traefik/local/certs/local.ext > ./assets/traefik/local/certs/local.ext.tmp; \
	docker run --rm -it -v ./assets/traefik/local/certs/:/etc/traefik/certs/ \
		-w /etc/traefik/certs/ \
		alpine/openssl req \
			-newkey rsa:2048 -x509 -nodes -new -sha256 -days 365 \
    		-keyout "local.key" -out "local.crt" -subj "/CN=$(FIRST_HOSTNAME)" \
    		-reqexts req_ext -extensions req_ext -config local.ext.tmp

.PHONY: network
network:  # Create network
	docker network create $(PROJECT_NAME) || true

.PHONY: stop-network
stop-network:  # Destroy network
	docker network rm $(PROJECT_NAME) || true

.PHONY: open
open:  # Open dashboard in browser
	open http://$(PROXY_HOST):8080/dashboard

.PHONY: sh
sh:  # Bash into container
	@docker exec -it $$(docker ps -asf "name=$(PROJECT_NAME)" | grep -v CONTAINER | cut -d' ' -f1) sh

.PHONY: check
check: venv  # Run linters and formatters
	@$(ACTIVATE) pre-commit run --all

.PHONY: clean
clean: stop  # Clean all files
	@git clean -Xdf
