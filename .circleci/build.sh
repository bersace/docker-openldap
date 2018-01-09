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
    docker ps -q | xargs -rt docker rm --force --volumes
}

docker build -t bersace/openldap:latest .
docker create -v /docker-entrypoint-init.d --name data alpine:3.4 /bin/true
find test -type f | xargs -tI % docker cp % data:/docker-entrypoint-init.d/
docker run \
       --name openldap --hostname ldap.openldap.docker \
       --rm --detach \
       --publish 389:389 --publish 636:636 \
       --volumes-from data \
       bersace/openldap:latest
trap teardown INT EXIT TERM
docker ps

: Test SSL
retry 'echo | openssl s_client -connect ldap.openldap.docker:636 -showcerts'

: Test LDAP
retry ldapwhoami -d 256 \
      -H ldap://ldap.openldap.docker \
      -D cn=admin,dc=ldap,dc=openldap,dc=docker -xw admin
