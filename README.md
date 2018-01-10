# OpenLDAP Container Image

[![Docker Image](https://images.microbadger.com/badges/image/bersace/openldap.svg)](https://hub.docker.com/r/bersace/openldap)
[![CI](https://circleci.com/gh/bersace/docker-openldap.svg?style=shield)](https://circleci.com/gh/bersace/docker-openldap)

`bersace/openldap` tries to be as simple as official Postgres image.

- Based on `debian:stretch-slim`.
- Shipped with SASL modules.
- Simple self-signed TLS for testing purpose.
- Extensible with `/docker-entrypoint-init.d/`.


## Environment variables

Some variables are mandatory for bootstrap.

- `LDAP_ADMIN_PASSWORD` contains clear admin password. Defaults to `admin`.
- `LDAP_DOMAIN`, the DNS style domain managed by the directory. Defaults to
  FQDN.
- `LDAP_ORGANISATION`, the human readable name of the root organisation.
  Defaults to `Unknown`.
- `LDAP_BACKEND`: defaults to `mdb`.


## Customizing Bootstrap

If OpenLDAP database is empty, entrypoint triggers a bootstrap procedure. You
can hook this procedure with files in `/docker-entrypoint-init.d/`. File ending
with `.sh` is sourced. File ending with `ldif` is processed either by `ldapadd`
or `ldapmodify`.

In bootstrap scripts are executed as root. A temporary `slapd` instance is
running on UNIX socket to avoid using `slapadd`. Use OpenLDAP tools like
`ldapsearch`, `ldapadd` or `ldapmodify` without arguments. `LDAP*` environment
variables are properly set for this purpose.

Entrypoint preprocess `.ldif` files with `envsubst`. `${LDAPBASE}`,
`${LDAP_BACKEND}` and `${LDAP_DOMAIN}` are substituted.
