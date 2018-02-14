FROM centos:5

EXPOSE 389
VOLUME /var/lib/ldap
VOLUME /var/backups
VOLUME /docker-entrypoint-init.d
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

RUN rm -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/libselinux.repo \
    && sed -i '/5.9/,$d' /etc/yum.repos.d/CentOS-Vault.repo \
    && sed -i 's/5.10/5.11/g;s/enabled=0/enabled=1/' /etc/yum.repos.d/CentOS-Vault.repo \
    && sed -i /plugins=1/d /etc/yum.conf \
    && yum repolist enabled

RUN yum makecache update \
    && yum install -y \
        gettext \
        openldap-clients \
        openldap-servers \
    && yum clean all

ADD entrypoint.sh /usr/local/bin/docker-entrypoint.sh
