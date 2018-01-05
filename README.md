# OpenLDAP Container Image

This container image for OpenLDAP tries to be as simple as official Postgres
image.

- Based on `debian:stretch-slim`.
- Shipped with SASL modules.
- Extensible with `/docker-entrypoint-init.d/`.


## Mandatory configuration

You **must** configure entrypoint with the following environment variables:

- `LDAP_ADMIN_PASSWORD` contains clear admin password.
- `LDAP_DOMAIN`, the DNS style domain managed by the directory.
- `LDAP_ORGANISATION`, the human readable name of the root organisation.


## Customizing Bootstrap

If OpenLDAP database is empty, entrypoint triggers a bootstrap procedure. You
can hook this procedure with files in `/docker-entrypoint-init.d/`. File ending
with `.sh` is sourced. File ending with `ldif` is processed either by `ldapadd`
or `ldapmodify`.

In bootstrap scripts, you are root and can use OpenLDAP tools like `ldapsearch`,
`ldapadd` or `ldapmodify` without arguments. `~/.ldaprc` is properly configured.
A temporary `slapd` instance is running on UNIX socket to use `ldap*` tools,
avoid using `slapadd`.

Entrypoint preprocess `.ldif` files with `envsubst`. For now, only `${LDAPBASE}`
is substituted.
