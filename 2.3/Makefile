NAME=bersace/openldap
VERSION=2.3

default:

build:
	docker build -t $(NAME):$(VERSION) .

clean:
	docker-compose down -v
	docker images --quiet $(NAME):$(VERSION) | xargs --no-run-if-empty --verbose docker rmi -f

dev:
	docker-compose down -v
	docker-compose up -d

enter:
	docker-compose exec ldap /bin/bash

.PHONY: test
test:
	docker run --rm --label com.dnsdock.alias=ldap.openldap.docker --env LDAP_ADMIN_PASSWORD=admin --env LDAP_DOMAIN=ldap.openldap.docker --env LDAP_ORGANISATION=ACME $(NAME):$(VERSION)
