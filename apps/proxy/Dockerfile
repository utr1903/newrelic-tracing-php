FROM php:8.1-apache

### General ###
RUN apt-get update
RUN echo Y | apt-get upgrade
RUN echo Y | apt-get install zip

RUN a2enmod rewrite
######

### Composer ###
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm composer-setup.php

RUN /usr/local/bin/composer self-update
RUN /usr/local/bin/composer require newrelic/monolog-enricher -W --quiet
RUN /usr/local/bin/composer require curl/curl -W --quiet
######

### New Relic ###
ARG newRelicAppName
ARG newRelicLicenseKey
ARG newRelicDaemonAddress

RUN \
  curl -L "https://download.newrelic.com/php_agent/archive/10.2.0.314/newrelic-php5-10.2.0.314-linux.tar.gz" | tar -C /tmp -zx && \
  export NR_INSTALL_USE_CP_NOT_LN=1 && \
  export NR_INSTALL_SILENT=1 && \
  /tmp/newrelic-php5-*/newrelic-install install && \
  rm -rf /tmp/newrelic-php5-* /tmp/nrinstall*

RUN sed -i \
    -e "s/\"REPLACE_WITH_REAL_KEY\"/$newRelicLicenseKey/" \
    -e "s/newrelic.appname = \"PHP Application\"/newrelic.appname = $newRelicAppName/" \
    -e "s/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/" \
    -e "s/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/" \
    -e "s/;newrelic.daemon.address =.*/newrelic.daemon.address = $newRelicDaemonAddress/" \
    -e "s/;newrelic.application_logging.enabled =.*/newrelic.application_logging.enabled = true/" \
    -e "s/;newrelic.application_logging.forwarding.enabled =.*/newrelic.application_logging.forwarding.enabled = true/" \
    -e "s/;newrelic.application_logging.forwarding.log_level =.*/newrelic.application_logging.forwarding.log_level = \"INFO\"/" \
    /usr/local/etc/php/conf.d/newrelic.ini
######

COPY . .
