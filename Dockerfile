FROM registry.access.redhat.com/ubi8/php-74@sha256:267ee7fa444c157d3bab68b8fa01d2862ec15a6d487e4b0836b9b8ea2be1e414

# Add application sources to a directory that the assemble script expects them
# and set permissions so that the container runs without root access
USER 0

COPY mssql-release.repo /etc/yum.repos.d/mssql-release-repo

#ARG YUM_DEPENDENCIES=unixODBC-devel\ openldap-devel\ msodbcsql17\ mssql-tools\ php-devel\ php-pear

ARG YUM_DEPENDENCIES=unixODBC-devel\ openldap-devel\ php-devel\ php-pear

RUN set -x \
    && yum update -y \
    && ACCEPT_EULA=Y yum install -y $YUM_DEPENDENCIES \
    && yum clean all -y \
    && rm -rf /var/cache/yum

COPY sqlsrv-5.10.1.tgz /tmp

RUN pear config-set php_ini /etc/php.ini \
    && pear install /tmp/sqlsrv-5.10.1.tgz

ADD app-src /opt/app-root/src
RUN chown -R 1001:0 /opt/app-root/src

USER 1001

RUN TEMPFILE=$(mktemp) \
    && curl -o "$TEMPFILE" "https://getcomposer.org/installer" \
    && php <"$TEMPFILE" \
    && ./composer.phar install --no-interaction --no-ansi --optimize-autoloader \
    && chgrp -R 0 ./ \
    && chmod -R g+rwX ./

# Set the default command for the resulting image
CMD /usr/libexec/s2i/run
