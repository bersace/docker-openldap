# OpenLDAP 2.3 Container Image

`bersace/openldap:2.3` is a best effort at providing an OpenLDAP 2.3 Docker
image as simple as latest.

- Based on `centos:5`.
- Extensible with `/docker-entrypoint-init.d/`.


## Environment variables

Some variables are mandatory for bootstrap.

- `LDAP_ADMIN_PASSWORD` contains clear admin password. Defaults to `admin`.
- `LDAP_DOMAIN`, the DNS style domain managed by the directory. Defaults to
  FQDN.
- `LDAP_ORGANISATION`, the human readable name of the root organisation.
  Defaults to `Unknown`.


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
