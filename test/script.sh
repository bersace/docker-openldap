# Test file LDAP script and access to database

ldapadd <<EOF
version: 2
charset: UTF-8

dn: ou=Script,${LDAPBASE}
objectclass: organizationalUnit
objectclass: top
ou: Script
EOF
