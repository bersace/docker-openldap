# OpenLDAP Container Image

This container image for OpenLDAP tries to be as simple as official Postgres
image.

- Based on `debian:stretch-slim`.
- Shipped with SASL modules.
- Simple self-signed TLS for testing purpose.
- Extensible with `/docker-entrypoint-init.d/`.


## Environment variables

Some variables are mandatory for bootstrap.

- **Mandatory**: `LDAP_ADMIN_PASSWORD` contains clear admin password.
- **Mandatory**: `LDAP_DOMAIN`, the DNS style domain managed by the directory.
- **Mandatory**: `LDAP_ORGANISATION`, the human readable name of the root organisation.
- `LDAP_BACKEND`: defaults to hdb.


## Customizing Bootstrap

If OpenLDAP database is empty, entrypoint triggers a bootstrap procedure. You
can hook this procedure with files in `/docker-entrypoint-init.d/`. File ending
with `.sh` is sourced. File ending with `ldif` is processed either by `ldapadd`
or `ldapmodify`.

In bootstrap scripts, you are root and can use OpenLDAP tools like `ldapsearch`,
`ldapadd` or `ldapmodify` without arguments. `~/.ldaprc` is properly configured.
A temporary `slapd` instance is running on UNIX socket to use `ldap*` tools,
avoid using `slapadd`.

Entrypoint preprocess `.ldif` files with `envsubst`. `${LDAPBASE}` and
`${LDAP_BACKEND}` are substituted.
