#!/bin/bash -eux

addormodify() {
    if grep -q changetype $1 ; then
        envsubst '${LDAPBASE}' <$1 | ldapmodify
    else
        envsubst '${LDAPBASE}' <$1 | ldapadd
    fi
}

catchall() {
    tail -f /dev/null
}

retry() {
    for i in {0..30} ; do
        $@ && return
        sleep $i
    done
    $@
}


if [ -n "${DEBUG-}" ] ; then
    trap catchall INT TERM EXIT
else
    EXEC=1
fi

: ${LDAP_LOGLEVEL:=256}

if ! readlink -e /var/lib/ldap/*.bdb > /dev/null ; then
    # Bootstrap OpenLDAP configuration and data
    debconf-set-selections <<EOF
slapd slapd/internal/generated_adminpw password ${LDAP_ADMIN_PASSWORD}
slapd slapd/internal/adminpw password ${LDAP_ADMIN_PASSWORD}
slapd slapd/password2 password ${LDAP_ADMIN_PASSWORD}
slapd slapd/password1 password ${LDAP_ADMIN_PASSWORD}
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/domain string ${LDAP_DOMAIN}
slapd shared/organization string ${LDAP_ORGANISATION}
slapd slapd/backend string HDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOF
    dpkg-reconfigure -f noninteractive slapd

    # Now start a local slapd instance bound to unix socket only. This allow to
    # use ldapadd and ldapmodify instead of slapadd. That may change once
    # OpenLDAP 2.5 comes with slapmodify.

    suffix_line=$(slapcat -n0 -s olcDatabase={1}hdb,cn=config | grep olcSuffix)
    export LDAPBASE=${suffix_line#olcSuffix: }
    export LDAPSASL_MECH=EXTERNAL
    export LDAPURI=ldapi:///
    cat > /root/.ldaprc << EOF
BASE        ${LDAPBASE}
SASL_MECH   ${LDAPSASL_MECH}
URI         ${LDAPURI}
EOF

    slapd -h "${LDAPURI}" -u openldap -g openldap -d ${LDAP_LOGLEVEL} &
    retry test -S /run/slapd/ldapi
    # Check the connexion
    ldapwhoami -d ${LDAP_LOGLEVEL}

    # Allow local users to manage database
    ldapmodify <<EOF
dn: olcDatabase={1}hdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
olcAccess: {1}to *
  by dn.children="cn=external,cn=auth" manage
  by self write
  by users read
  by anonymous auth
  by * none
EOF

    for f in $(find /docker-entrypoint-init.d/ -type f | sort); do
        case $f in
            *.ldif)    addormodify $f ;;
            *.sh)      . $f ;;
            *)         : ignoring $f ;;
        esac
    done

    pid=$(cat /run/slapd/slapd.pid)
    kill -TERM $pid
    retry test '!' -d /proc/$pid/
fi

ulimit -n 1024

${EXEC+exec} \
    /usr/sbin/slapd \
    -h "ldap://0.0.0.0" \
    -u openldap -g openldap \
    -d ${LDAP_LOGLEVEL} \
    $@
