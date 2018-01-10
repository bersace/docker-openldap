FROM debian:stretch-slim

EXPOSE 389 636
VOLUME /var/lib/ldap
VOLUME /var/backups
VOLUME /docker-entrypoint-init.d
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

RUN apt-get -y update \
    && LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      gettext-base \
      ldap-utils \
      libsasl2-modules \
      libsasl2-modules-db \
      libsasl2-modules-gssapi-mit \
      libsasl2-modules-ldap \
      libsasl2-modules-otp \
      libsasl2-modules-sql \
      openssl \
      slapd \
      krb5-kdc-ldap \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD entrypoint.sh /usr/local/bin/docker-entrypoint.sh
