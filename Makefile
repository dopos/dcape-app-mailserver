## dcape-app-mailserver Makefile
## This file extends Makefile.app from dcape
#:

SHELL            = /bin/bash
CFG             ?= .env
CFG_BAK         ?= $(CFG).bak

#- Docker repo & image name without version
IMAGE           ?= ghcr.io/docker-mailserver/docker-mailserver

#- ver
IMAGE_VER       ?= 13.1.0

# ------------------------------------------------------------------------------
# app custom config

# Owerwrite for setup
APP_SITE        ?= mail.dev.test

#- app root
APP_ROOT        ?= $(PWD)

#- External SMTP port
SMTP_LISTEN     ?= 25
#- Max message size
POSTFIX_MESSAGE_SIZE_LIMIT ?= 52428800

#- Relay setup
RELAY_HOST      ?=
#- Relay setup
RELAY_PORT      ?=
#- Relay setup
RELAY_USER      ?=
#- Relay setup
RELAY_PASSWORD  ?=

#- SSL type
#-empty => SSL disabled
#-letsencrypt => Enables Let's Encrypt certificates
SSL_TYPE        ?= letsencrypt

# Copy from image to persist dir (always)
PERSIST_FILES    = .git .env Makefile docker-compose.yml
# Keep persistent dir on deploy
APP_ROOT_OPTS    = keep

# ------------------------------------------------------------------------------

# if exists - load old values
-include $(CFG_BAK)
export

-include $(CFG)
export

# ------------------------------------------------------------------------------
# Find and include DCAPE_ROOT/Makefile
DCAPE_COMPOSE   ?= dcape-compose
DCAPE_ROOT      ?= $(shell docker inspect -f "{{.Config.Labels.dcape_root}}" $(DCAPE_COMPOSE))

ifeq ($(shell test -e $(DCAPE_ROOT)/Makefile.app && echo -n yes),yes)
  include $(DCAPE_ROOT)/Makefile.app
else
  include /opt/dcape/Makefile.app
endif
# ------------------------------------------------------------------------------

user-add:
	docker run --rm \
	  -e MAIL_USER=$(USER_EMAIL) \
	  -e MAIL_PASS=$(USER_PASS) \
	  -ti $$IMAGE:$$IMAGE_VER \
	  /bin/sh -c 'echo "$$MAIL_USER|$$(doveadm pw -s SHA512-CRYPT -u $$MAIL_USER -p $$MAIL_PASS)"' >> $(APP_ROOT)/config/postfix-accounts.cf

# ------------------------------------------------------------------------------

dkim-add:
	docker run --rm \
	  -v $(DATA_PATH)/config:/tmp/docker-mailserver \
	  -ti $$IMAGE:$$IMAGE_VER generate-dkim-config

dkim: CMD=exec app setup config dkim domain '$(DOMAIN)'
dkim: dc

IP ?= 1.1.1.1

## make ban IP=1.1.1.1[/24]
ban:
	@echo -n "$(IP): "
	@docker exec $(APP_TAG)-app-1 setup fail2ban ban "$(IP)"

BAN_APP ?= custom

## make app-ban IP=1.1.1.0[/24] BAN_APP=postfix
app-ban:
	docker exec $(APP_TAG)-app-1 fail2ban-client set $(BAN_APP) banip "$(IP)"

## make app-unban IP=1.1.1.0[/24] BAN_APP=postfix
app-unban:
	docker exec $(APP_TAG)-app-1 fail2ban-client set $(BAN_APP) unbanip "$(IP)"
