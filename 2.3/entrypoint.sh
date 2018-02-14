#!/bin/bash -eux

addormodify() {
    local substitutions='${LDAPBASE} ${LDAP_DOMAIN}'
    if grep -q changetype $1 ; then
        envsubst "$substitutions" <$1 | ldapmodify
    else
        envsubst "$substitutions" <$1 | ldapadd
    fi
}

bootstrap_database() {
    cat > /etc/openldap/slapd.conf <<EOF
#
# See slapd.conf(5) for details on configuration options.
# This file should NOT be world readable.
#
include		/etc/openldap/schema/core.schema
include		/etc/openldap/schema/cosine.schema
include		/etc/openldap/schema/inetorgperson.schema
include		/etc/openldap/schema/nis.schema

# Do not enable referrals until AFTER you have a working directory
# service AND an understanding of referrals.
#referral	ldap://root.openldap.org

pidfile		/var/run/openldap/slapd.pid
argsfile	/var/run/openldap/slapd.args

# Load dynamic backend modules:
# modulepath	/usr/lib64/openldap

# Modules available in openldap-servers-overlays RPM package
# Module syncprov.la is now statically linked with slapd and there
# is no need to load it here
# moduleload accesslog.la
# moduleload auditlog.la
# moduleload denyop.la
# moduleload dyngroup.la
# moduleload dynlist.la
# moduleload lastmod.la
# moduleload pcache.la
# moduleload ppolicy.la
# moduleload refint.la
# moduleload retcode.la
# moduleload rwm.la
# moduleload smbk5pwd.la
# moduleload translucent.la
# moduleload unique.la
# moduleload valsort.la

# modules available in openldap-servers-sql RPM package:
# moduleload back_sql.la

# The next three lines allow use of TLS for encrypting connections using a
# dummy test certificate which you can generate by changing to
# /etc/pki/tls/certs, running "make slapd.pem", and fixing permissions on
# slapd.pem so that the ldap user or group can read it.  Your client software
# may balk at self-signed certificates, however.
# TLSCACertificateFile /etc/pki/tls/certs/ca-bundle.crt
# TLSCertificateFile /etc/pki/tls/certs/slapd.pem
# TLSCertificateKeyFile /etc/pki/tls/certs/slapd.pem

# Sample security restrictions
#	Require integrity protection (prevent hijacking)
#	Require 112-bit (3DES or better) encryption for updates
#	Require 63-bit encryption for simple bind
# security ssf=1 update_ssf=112 simple_bind=64

# Sample access control policy:
#	Root DSE: allow anyone to read it
#	Subschema (sub)entry DSE: allow anyone to read it
#	Other DSEs:
#		Allow self write access
#		Allow authenticated users read access
#		Allow anonymous users to authenticate
#	Directives needed to implement policy:
# access to dn.base="" by * read
# access to dn.base="cn=Subschema" by * read
# access to *
#	by self write
#	by users read
#	by anonymous auth
#
# if no access controls are present, the default policy
# allows anyone and everyone to read anything but restricts
# updates to rootdn.  (e.g., "access to * by * read")
#
# rootdn can always read and write EVERYTHING!

#######################################################################
# ldbm and/or bdb database definitions
#######################################################################

database	bdb
suffix		"${LDAPBASE}"
rootdn		"cn=admin,${LDAPBASE}"
# Cleartext passwords, especially for the rootdn, should
# be avoided.  See slappasswd(8) and slapd.conf(5) for details.
# Use of strong authentication encouraged.
# rootpw		secret
# rootpw		{crypt}ijFYNcSNctBYg
rootpw    $(slappasswd -s "${LDAP_ADMIN_PASSWORD}")
access to attrs=userPassword by self write by anonymous auth by * none
access to *
  by dn.children="cn=peercred,cn=external,cn=auth" manage
  by self write
  by users read
  by anonymous auth
  by * none

# The database directory MUST exist prior to running slapd AND
# should only be accessible by the slapd and slap tools.
# Mode 700 recommended.
directory	/var/lib/ldap

# Indices to maintain for this database
index objectClass                       eq,pres
index ou,cn,mail,surname,givenname      eq,pres,sub
index uidNumber,gidNumber,loginShell    eq,pres
index uid,memberUid                     eq,pres,sub
index nisMapName,nisMapEntry            eq,pres,sub

# Replicas of this database
#replogfile /var/lib/ldap/openldap-master-replog
#replica host=ldap-1.example.com:389 starttls=critical
#     bindmethod=sasl saslmech=GSSAPI
#     authcId=host/ldap-master.example.com@EXAMPLE.COM
EOF
    slapadd <<EOF
dn: ${LDAPBASE}
objectclass: dcObject
objectclass: organization
o: ${LDAP_ORGANISATION}
dc: ${LDAP_DOMAIN%%.*}
EOF
    cp /etc/openldap/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
    slapindex
    chown -R ldap:ldap /var/lib/ldap
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

# Check if database #1 exists
if ! slapcat -n 1 -a cn=never_found 2>/dev/null; then
    : ${LDAP_ADMIN_PASSWORD:=admin}
    export LDAP_BACKEND=bdb
    export LDAP_DOMAIN=${LDAP_DOMAIN-$(hostname --fqdn)}
    export LDAPBASE=dc=${LDAP_DOMAIN//./,dc=}

    bootstrap_database

    export LDAPSASL_MECH=EXTERNAL
    export LDAPURI=ldapi:///

    # Now start a local slapd instance bound to unix socket only. This allow to
    # use ldapadd and ldapmodify instead of slapadd.

    /usr/sbin/slapd -h "${LDAPURI}" -u ldap -g ldap -d ${LDAP_LOGLEVEL} &
    retry test -S /var/run/ldapi
    # Check the connexion
    retry ldapwhoami -d ${LDAP_LOGLEVEL}

    for f in $(find /docker-entrypoint-init.d/ -type f | sort); do
        case $f in
            *.ldif)    addormodify $f ;;
            *.sh)      . $f ;;
            *)         : ignoring $f ;;
        esac
    done

    pid=$(cat /var/run/openldap/slapd.pid)
    kill -TERM $pid
    retry test '!' -d /proc/$pid/
fi

ulimit -n 1024

${EXEC+exec} \
    /usr/sbin/slapd \
    -h "ldap://0.0.0.0" \
    -u ldap -g ldap \
    -d ${LDAP_LOGLEVEL} \
    $@
