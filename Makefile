# dcape-app-mattermost Makefile

SHELL               = /bin/sh
CFG                ?= .env

# Site domain
APP_DOMAIN         ?= dev.lan
# Site host
APP_HOST           ?= mail
# Site fqdn
APP_SITE           ?= $(APP_HOST).$(APP_DOMAIN)

# Use SSL
#empty => SSL disabled
#letsencrypt => Enables Let's Encrypt certificates
SSL_TYPE           ?= letsencrypt

# Vars for `make user-add`
# Email user name
MAIL_USER          ?= admin@$(APP_DOMAIN)
# Email user password
MAIL_PASS          ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)

# Docker image name
IMAGE              ?= tvial/docker-mailserver
# Docker image tag
IMAGE_VER          ?= :release-v7.2.0

# dcape v2 traefik parent dir (/opt/dcape/var)
DCAPE_ROOT         ?= ./../../
# dcape v2 app root for drone
APP_ROOT           ?= $(PWD)

# Docker-compose project name (container name prefix)
COMPOSE_PROJECT_NAME ?= mail

# Docker-compose image tag
DC_VER             ?=

define CONFIG_DEF
# ------------------------------------------------------------------------------
# Mattermost settings

# Site domain
APP_DOMAIN=$(APP_DOMAIN)
# Site host
APP_HOST=$(APP_HOST)
# Site fqdn
APP_SITE=$(APP_SITE)

# SSL
SSL_TYPE=$(SSL_TYPE)

# Docker details

# Docker image name
IMAGE=$(IMAGE)
# Docker image tag
IMAGE_VER=$(IMAGE_VER)
# Docker-compose project name (container name prefix)
COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME)

# dcape v2 traefik parent dir (/opt/dcape/var)
DCAPE_ROOT=$(DCAPE_ROOT)
# dcape v2 app root for drone
APP_ROOT=$(APP_ROOT)

endef
export CONFIG_DEF

-include $(CFG)
export

.PHONY: all $(CFG).sample start start-hook stop update up reup down dc help

all: help

# ------------------------------------------------------------------------------
# webhook commands

start: up

start-hook: reup

stop: down

update: reup

# ------------------------------------------------------------------------------
# docker commands

## старт контейнеров
up:
up: CMD=up -d
up: dc

## рестарт контейнеров
reup:
reup: CMD=up --force-recreate -d
reup: dc

## остановка и удаление всех контейнеров
down:
down: CMD=rm -f -s
down: dc


# $$PWD используется для того, чтобы текущий каталог был доступен в контейнере по тому же пути
# и относительные тома новых контейнеров могли его использовать
## run docker-compose
dc: docker-compose.yml
	@docker run --rm  \
	  -v /var/run/docker.sock:/var/run/docker.sock \
	  -v $$PWD:$$PWD \
	  -w $$PWD \
	  docker/compose$(DC_VER) \
	  $(CMD)

# ------------------------------------------------------------------------------

user-add:
	docker run --rm \
	  -e MAIL_USER=$(MAIL_USER) \
	  -e MAIL_PASS=$(MAIL_PASS) \
	  -ti $$IMAGE$$IMAGE_VER \
	  /bin/sh -c 'echo "$$MAIL_USER|$$(doveadm pw -s SHA512-CRYPT -u $$MAIL_USER -p $$MAIL_PASS)"' >> ../../data/mail/config/postfix-accounts.cf

# ------------------------------------------------------------------------------

dkim-add:
	docker run --rm \
	  -v $$PWD/../../data/mail/config:/tmp/docker-mailserver \
	  -ti $$IMAGE$$IMAGE_VER generate-dkim-config

# ------------------------------------------------------------------------------

certs:
	[ -f dumpcerts.sh ] || wget https://github.com/containous/traefik/raw/v1.7/contrib/scripts/dumpcerts.sh
	[ -d ../../data/mail/certs/ ] || mkdir ../../data/mail/certs/
	bash dumpcerts.sh ../../data/acme/certs.json ../../data/mail/certs/
# ------------------------------------------------------------------------------

$(CFG).sample:
	@[ -f $@ ] || { echo "$$CONFIG_DEF" > $@ ; echo "Warning: Created default $@" ; }

# ------------------------------------------------------------------------------

## List Makefile targets
help:
	@grep -A 1 "^##" Makefile | less

##
## Press 'q' for exit
##
