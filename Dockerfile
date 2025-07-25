ARG PHP_VERSION

FROM php:${PHP_VERSION}-alpine
MAINTAINER eiriksm <eirik@morland.no>

ENV COMPOSER_DISCARD_CHANGES=1
ENV COMPOSER_MEMORY_LIMIT=-1
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_PROCESS_TIMEOUT=1200
ENV DRUPAL_CONTRIB_SA_PATH=/root/drupal-contrib-sa

ARG PHP_VERSION
ENV PHP_VERSION=${PHP_VERSION}

COPY --from=composer/composer:latest-bin /composer /usr/bin/composer
COPY ./php-install.sh /root/
COPY php-base.ini /usr/local/etc/php/conf.d/

RUN /bin/sh /root/php-install.sh
