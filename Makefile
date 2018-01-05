NAME=bersace/openldap
VERSION=latest

default:

build:
	docker build -t $(NAME):$(VERSION) .

clean:
	docker-compose down -v
	docker images --quiet $(NAME) | xargs --no-run-if-empty --verbose docker rmi -f

debug:
	docker-compose exec ldap /bin/bash

dev:
	docker-compose down -v
	docker-compose up -d

.PHONY: test
test:
	docker run --rm --label com.dnsdock.alias=ldap.openldap.docker --env LDAP_ADMIN_PASSWORD=admin --env LDAP_DOMAIN=ldap.openldap.docker --env LDAP_ORGANISATION=ACME $(NAME):$(VERSION)
