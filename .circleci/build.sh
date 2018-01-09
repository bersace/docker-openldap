#!/bin/sh

set -eux

retry() {
    for i in 1 2 3 5 8; do
        docker exec openldap bash -c "$*" && return
        sleep $i
    done
    docker exec openldap bash -c "$*"
}

teardown() {
    docker logs openldap
    docker rm --force --volumes openldap ||:
}

docker build -t bersace/openldap:latest .
docker run \
       --name openldap --hostname ldap.openldap.docker \
       --rm --detach \
       --publish 389:389 --publish 636:636 \
       bersace/openldap:latest
trap teardown INT EXIT TERM
docker ps

: Test SSL
retry 'echo | openssl s_client -connect ldap.openldap.docker:636 -showcerts'

: Test LDAP
retry ldapwhoami -d 256 \
      -H ldap://ldap.openldap.docker \
      -D cn=admin,dc=ldap,dc=openldap,dc=docker -xw admin
