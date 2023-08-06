.DEFAULT_GOAL := start

ACTIVATE = . venv/bin/activate;
ASSETS = $(shell find assets -type f -name '*')
PROJECT_NAME = proxy

.git/hooks/pre-commit: venv
	$(ACTIVATE) pre-commit install
	@touch $@

venv: venv/.touchfile
venv/.touchfile: requirements.txt
	test -d venv || virtualenv venv
	$(ACTIVATE) pip install -Ur requirements.txt
	@touch $@

setup: venv .git/hooks/pre-commit build

build: venv/.build_touchfile
venv/.build_touchfile: Dockerfile $(ASSETS)
	docker build -t $(PROJECT_NAME) .
	@touch $@

.PHONY: start
start: setup network
	HOSTNAME=$(PROJECT_NAME).local docker compose up -d

.PHONY: restart
restart: stop start

.PHONY: stop
stop:
	docker compose down --remove-orphans
	$(MAKE) stop-network

.PHONY: network
network:
	docker network create $(PROJECT_NAME) || true

.PHONY: stop-network
stop-network:
	docker network rm $(PROJECT_NAME) || true

.PHONY: dashboard
dashboard:
	open http://proxy.local:8080/dashboard

.PHONY: sh
sh:
	@docker exec -it $$(docker ps -asf "name=$(PROJECT_NAME)" | grep -v CONTAINER | cut -d' ' -f1) sh
