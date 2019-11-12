DOCKER_PSQL="docker-compose exec postgres psql -U zotonic"
SSH_USER=$(shell whoami)
REMOTE_SITES_DIR=/srv/zotonic/sites
REMOTE_BACKUP_PATH=$(REMOTE_SITES_DIR)/$(site)/files/backup
REMOTE_BACKUP_FILE=$(shell ssh $(SSH_USER)@$(host) ls "$(REMOTE_BACKUP_PATH)/*.sql" -t | head -n1 | xargs -n1 basename)
target test: url=http://$(site).docker.test:8000
target test-chrome: url=http://$(site).docker.test

include .env

NPM_PATH := ./node_modules/.bin
export PATH := $(NPM_PATH):$(PATH)
export JSX_FORCE_MAPS := 1
export ERLASTIC_SEARCH_JSON_MODULE := jsx

help:
	@echo "Run: make <target> where <target> is one of the following:"
	@echo "  addsite name=site-name  Create a new site"
	@echo "  api-doc                 Generate API doc"
	@echo "  deps                    Install dependencies"
	@echo "  disco                   Make your site available at http://[sitename].[username].ginger.test"
	@echo "  down                    Stop containers"
	@echo "  dump-db site=site-name  Dump database to /data directory using pg_dump"
	@echo "  gulp site=your_site     Run Gulp in a site directory"
	@echo "  clean-node              Delete all node_modules directories"
	@echo "  import-db-file          Import database from file in ginger data dir (site=site-name file=site-dump.sql)"
	@echo "  import-db-backup        Import database from a backup (host=ginger.driebit.net site=site-name)"
	@echo "  prompt                  Open shell prompt at Zotonic container"
	@echo "  shell                   Open Zotonic shell"
	@echo "  psql                    Open PostgreSQL interactive terminal"
	@echo "  start                   Run Zotonic on the host and all other services in containers"
	@echo "  switch site=site-name   Switch Ginger and Zotonic to the versions declared by a site's .env file"
	@echo "  test site=site-name     Run browser site tests in Docker container (args=Nightwatch arguments url=http://...)"
	@echo "  test-chrome =site-name  Run browser site tests locally (args=Nightwatch arguments url=http://...)"
	@echo "  tests                   Find all Ginger tests and run them"
	@echo "  up                      Start containers"
	@echo "  up-support              Start all containers except Zotonic itself (for running Zotonic outside Docker)"
	@echo "  up-zotonic              Start containers with custom Zotonic checkout"
	@echo "  update                  Update containers"

addsite:
	@docker-compose exec zotonic bin/zotonic addsite -s ginger -H $(name).docker.test $(name)

api-doc:
	@yaml2json docs/rest-api.yaml > /tmp/rest-api.json
	@spectacle -1 -t /tmp -f ginger-rest-api.html /tmp/rest-api.json

deps:
	@npm install
gulp:
	# Env MODULES_DIR can be used in Gulpfiles, if necessary.
	docker run --rm -it -p 35729:35729 --workdir /app -v "`pwd`/sites/$(site)":/app:delegated -v "`pwd`/modules":/modules:delegated --env MODULES_DIR=/modules node:8.9.1-alpine sh -c "npm install && npm start"

clean-node:
	find . -type d -name node_modules -exec rm -r "{}" \;

down:
	@docker-compose down

import-db-file:
	@echo "> Importing $(site) from $(file)"
	@docker-compose exec zotonic bin/zotonic stopsite $(site)
	@docker-compose exec postgres psql -U zotonic -c "DROP DATABASE IF EXISTS $(site)"
	@docker-compose exec postgres psql -U zotonic -c "CREATE DATABASE $(site) ENCODING 'UTF8' TEMPLATE template0"
	@docker-compose exec postgres psql $(site) -U zotonic -h localhost -f $(file)
	@docker-compose exec zotonic bin/zotonic startsite $(site)

import-db-backup:
	@echo "> Importing $(REMOTE_BACKUP_FILE) from $(host) into $(site)"
	@scp $(ssh_user)@$(host):$(REMOTE_BACKUP_PATH)/$(REMOTE_BACKUP_FILE) data/
	@$(MAKE) import-db-file db=$(site) file=$(REMOTE_BACKUP_FILE)

dump-db:
	@docker-compose exec postgres pg_dump -U zotonic $(site) > data/$(site)_`date -u +"%Y-%m-%dT%H%M%SZ"`.sql

shell:
	@docker-compose exec zotonic bin/zotonic shell

prompt:
	@docker-compose run zotonic sh

psql:
	@docker-compose exec postgres psql -U zotonic

start: up-support
	echo "rdr pass inet proto tcp from any to any port 80 -> 127.0.0.1 port 8000" | sudo pfctl -ef -; true
	@bash -c "trap 'trap - SIGINT SIGTERM 0 ERR; docker-compose stop elasticsearch kibana postgres; exit 0' SIGINT SIGTERM 0 ERR; $(MAKE) start-zotonic"

start-zotonic:
	cd ${ZOTONIC}; bin/zotonic debug

switch:
	@source "sites/$(site)/.env"; git checkout $$GINGER_VERSION; cd ${ZOTONIC}; git checkout $$ZOTONIC_VERSION

test:
# Disconnect and reconnect the Ginger container to refresh the site alias (see docker-compose.yml).
	@docker network disconnect ginger_selenium ginger_zotonic_1
	@docker network connect ginger_selenium ginger_zotonic_1 --alias ${site}.docker.test

	SITE=$(site) docker-compose run --rm -v "`pwd`/tests":/app -v "`pwd`/sites/$(site)/features":/site/features -e LAUNCH_URL="$(url)" node-tests test -- $(args)
test-chrome:
# Disconnect and reconnect the Ginger container to refresh the site alias (see docker-compose.yml).
	FEATURES_PATH=../sites/$(site)/features LAUNCH_URL="$(url)" npm --prefix tests/ run test-chrome -- $(args)

.PHONY: tests
tests:
	docker-compose run --rm zotonic /scripts/runtests.sh

up:
	@docker-compose up --build zotonic kibana
	@echo "> Started. Open http://localhost in your browser."

up-support:
	@docker-compose up -d --build kibana postgres

up-zotonic:
# See https://github.com/zotonic/zotonic/issues/1321
	@docker-compose -f docker-compose.yml -f docker-compose.zotonic.yml up --build zotonic kibana
	@echo "> Started. Open http://localhost in your browser."

update:
	@docker-compose pull
	@docker pull driebit/node-gulp

disco:
	@docker run --dns 10.0.0.1 -d -p 8301:8301/udp -p 8301:8301 -e DOCKER_USER=$(USER) -e DOCKER_SERVICE=ginger -e DOCKER_PORT=80 driebit/disco:latest agent -rejoin -retry-join=10.0.0.10 -dc=office
