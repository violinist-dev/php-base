set -eu

apk add --no-cache unixodbc-dev brotli-dev gmp-dev yaml-dev samba-dev libldap openldap-dev pcre-dev libxslt-dev imap-dev sudo git libpng libjpeg libpq libxml2 mysql-client openssh-client rsync patch bash imagemagick libzip-dev \
    imagemagick-libs unixodbc-dev rabbitmq-c rabbitmq-c-dev mpdecimal-dev gettext gettext-dev imagemagick-dev librdkafka-dev autoconf g++ make icu-dev libpng-dev libjpeg-turbo-dev postgresql-dev libxml2-dev bzip2-dev icu icu-dev libmemcached-dev linux-headers $PHPIZE_DEPS

case $PHP_VERSION in
  8.6*)
    echo "Installing pie in place of pecl (pecl is not available yet for this alpha release)"
    curl -fsSL -o /usr/local/bin/pie https://github.com/php/pie/releases/latest/download/pie.phar
    chmod +x /usr/local/bin/pie
    # todo: Temp workaround for PHP 8.6.
    export BOX_REQUIREMENT_CHECKER=0
    apk add --no-cache libtool
    cat > /root/php86-pie-compat.h <<'EOC'
#ifndef EMPTY_SWITCH_DEFAULT_CASE
#define EMPTY_SWITCH_DEFAULT_CASE()
#endif
#ifndef INI_INT
#define INI_INT(name) ((zend_long) zend_ini_long((name), sizeof(name)-1, 0))
#endif
#ifndef INI_STR
#define INI_STR(name) zend_ini_string((name), sizeof(name)-1, 0)
#endif
#ifndef INI_FLT
#define INI_FLT(name) zend_ini_double((name), sizeof(name)-1, 0)
#endif
#ifndef ZEND_PARSE_PARAMS_THROW
#define ZEND_PARSE_PARAMS_THROW 0
#endif
EOC
    export CFLAGS="${CFLAGS:-} -DXtOffsetOf=offsetof -Dzval_dtor=zval_ptr_dtor_nogc -include /root/php86-pie-compat.h"
    ;;
  *)
    pecl channel-update pecl.php.net
    ;;
esac

case $PHP_VERSION in
  7.3)
    yes | pecl install mongodb-1.16.2
    ;;
  7.4|8.0)
    echo "yes" | pecl install mongodb-1.20.1
    ;;
  8.5*|8.6*)
    echo "Skipping mongo db driver for PHP $PHP_VERSION"
    ;;
  *)
    echo "yes" | pecl install mongodb
    ;;
esac

case $PHP_VERSION in
  8.5*|8.6*)
    echo "Skipping mongodb for PHP $PHP_VERSION"
    ;;
  *)
    docker-php-ext-enable mongodb
    ;;
esac

case $PHP_VERSION in
  8.0*)
    echo "" | pecl install swoole-5.1.7
    docker-php-ext-enable swoole
    ;;
  7.*)
    echo "" | pecl install swoole-4.8.13
    docker-php-ext-enable swoole
    ;;
  8.1*)
    echo "" | pecl install swoole-6.1.8
    docker-php-ext-enable swoole
    ;;
  8.5*|8.6*)
    echo "Skipping swoole for PHP $PHP_VERSION"
    ;;
  *)
    echo "" | pecl install swoole
    docker-php-ext-enable swoole
    ;;
esac

case $PHP_VERSION in
  7.3)
    yes | pecl install ds-1.4.0
    ;;
  7.4|8.0|8.1)
    yes | pecl install ds-1.6.0
    ;;
  8.6*)
    pie install php-ds/ext-ds
    ;;
  *)
    # If we really need it.
    php -m | grep -q '^ds$' || yes | pecl install ds
    ;;
esac

case $PHP_VERSION in
  8.5*)
    php -m | grep -q '^igbinary$' || (
      git clone --depth=1 https://github.com/igbinary/igbinary.git /usr/src/igbinary &&
      cd /usr/src/igbinary &&
      phpize && ./configure && make -j"$(nproc)" && make install &&
      echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini
    )
    rm -rf /usr/src/igbinary
    ;;
  8.6*)
    php -m | grep -q '^igbinary$' || (
      git clone --depth=1 https://github.com/igbinary/igbinary.git /usr/src/igbinary &&
      cd /usr/src/igbinary &&
      export CFLAGS="${CFLAGS:-} -DXtOffsetOf=offsetof -Dzval_dtor=zval_ptr_dtor_nogc" &&
      phpize && ./configure && make -j"$(nproc)" && make install &&
      echo "extension=igbinary.so" > /usr/local/etc/php/conf.d/igbinary.ini
    )
    rm -rf /usr/src/igbinary
    ;;
  *)
    yes | pecl install igbinary
    ;;
esac

case $PHP_VERSION in
  8.5*|8.6*)
    # Yknow if we really need it.
    php -m | grep -q '^mailparse$' || (
      git clone --depth=1 https://github.com/php/pecl-mail-mailparse.git /usr/src/mailparse &&
      cd /usr/src/mailparse &&
      phpize && ./configure && make -j"$(nproc)" && make install &&
      echo "extension=mailparse.so" > /usr/local/etc/php/conf.d/mailparse.ini
    )
    rm -rf /usr/src/mailparse
    ;;
  *)
    yes | pecl install mailparse
    ;;
esac

case $PHP_VERSION in
  8.6*)
    pie install apcu/apcu
    pie install rdkafka/rdkafka
    pie install pecl/yaml
    pie install pecl/uuid
    pie install msgpack/msgpack-php
    ;;
  *)
    yes | pecl install apcu rdkafka yaml uuid msgpack
    ;;
esac

case $PHP_VERSION in
  7.3)
    yes | pecl install decimal-1.5.1
    ;;
  7.4|8.0|8.1)
    yes | pecl install decimal-1.5.3
    ;;
  8.6*)
    pie install php-decimal/ext-decimal
    ;;
  *)
    yes | pecl install decimal
    ;;
esac

case $PHP_VERSION in
  7.3)
    echo "" | pecl install amqp-1.11.0
    ;;
  8.6*)
    pie install php-amqp/php-amqp
    ;;
  *)
    echo "" | pecl install amqp
    ;;
esac

case $PHP_VERSION in
  8.5*|8.6*)
    echo "Skipping oauth extension for $PHP_VERSION"
    ;;
  *)
    yes | pecl install oauth
    ;;
esac

case $PHP_VERSION in
  8.5*|8.6*)
    echo "Skipping memcached for PHP $PHP_VERSION"
    ;;
  *)
    echo "" | pecl install memcached
    docker-php-ext-enable memcached
    ;;
esac

case $PHP_VERSION in
  7.2)
    yes | pecl install sqlsrv-5.8.1 pdo_sqlsrv-5.8.1
    ;;
  7.3|7.4)
    yes | pecl install sqlsrv-5.10.1 pdo_sqlsrv-5.10.1
    ;;
  8.0)
    yes | pecl install sqlsrv-5.11.1 pdo_sqlsrv-5.11.1
    ;;
  8.1|8.2)
    yes | pecl install sqlsrv-5.12.0 pdo_sqlsrv-5.12.0
    ;;
  8.5*|8.6*)
    echo "Skipping sqlsrv on $PHP_VERSION"
    ;;
  *)
    yes | pecl install sqlsrv pdo_sqlsrv
    ;;
esac

case $PHP_VERSION in
  8.5*|8.6*)
    php -m | grep -q '^redis$' || (
      git clone --depth=1 https://github.com/phpredis/phpredis.git /usr/src/phpredis &&
      cd /usr/src/phpredis &&
      # Pin to a commit verified to build against the current PHP 8.6 base image.
      # phpredis tracks php-src's development branch closely, so its unpinned HEAD
      # can (and has) broken against whatever alpha/beta of 8.6 we're building.
      # Bump this hash when moving to a newer 8.6 pre-release.
      git checkout e3273a90fe0521de4c35a7410e186be68b70dff6 &&
      phpize && ./configure && make -j"$(nproc)" && make install &&
      echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini
    )
    rm -rf /usr/src/phpredis
    ;;
  8.*)
    mkdir -p /usr/src/php/ext/redis && curl -fsSL https://pecl.php.net/get/redis | tar xvz -C "/usr/src/php/ext/redis" --strip 1 && docker-php-ext-install redis
    ;;
  *)
    yes | pecl install redis-3.1.1
    docker-php-ext-enable redis
    ;;
esac

php -m | grep -q '^intl$' || docker-php-ext-configure intl
php -m | grep -q '^gettext$' || docker-php-ext-configure gettext
php -m | grep -q '^intl$' || docker-php-ext-install intl
php -m | grep -q '^gettext$' || docker-php-ext-install gettext
php -m | grep -q '^sockets$' || docker-php-ext-install sockets
case $PHP_VERSION in
  8.6*)
    echo "ds, yaml, decimal, uuid, msgpack, and amqp were already enabled by pie, and mailparse by its own install step, for PHP $PHP_VERSION"
    ;;
  *)
    docker-php-ext-enable ds yaml decimal uuid mailparse msgpack amqp
    ;;
esac

case $PHP_VERSION in
  8.5*|8.6*)
    echo "Skipping sqlsrv pdo_sqlsrv oauth for PHP $PHP_VERSION"
    ;;
  *)
    docker-php-ext-enable sqlsrv pdo_sqlsrv oauth
    ;;
esac


# ftp is compiled into PHP in < 8.2.
case $PHP_VERSION in
  8.4*|8.3|8.2)
    docker-php-ext-install ftp
    ;;
  *)
    echo "ftp extension already present on $PHP_VERSION"
    ;;
esac

# gd has slightly different build arguments on newer PHP.
case $PHP_VERSION in
  7.4|8.*)
    apk add --no-cache oniguruma-dev
    docker-php-ext-configure gd --with-jpeg=/usr
    ;;
  *)
    docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr
    ;;
esac

case $PHP_VERSION in
  8.0)
    pecl install xmlrpc-1.0.0RC2
    docker-php-ext-enable xmlrpc
    ;;
  8.*|8.4*)
    echo "skipping xmlrpc on PHP version $PHP_VERSION"
    ;;
  *)
    docker-php-ext-install xmlrpc
    docker-php-ext-enable xmlrpc
    ;;
esac

case $PHP_VERSION in
  8.6*)
    php -m | grep -q '^imagick$' || (
      git clone --depth=1 https://github.com/Imagick/imagick.git /usr/src/imagick &&
      cd /usr/src/imagick &&
      export CFLAGS="${CFLAGS:-} -DXtOffsetOf=offsetof" &&
      phpize && ./configure && make -j"$(nproc)" && make install &&
      echo "extension=imagick.so" > /usr/local/etc/php/conf.d/imagick.ini
    )
    rm -rf /usr/src/imagick
    ;;
  *)
    yes | pecl install imagick
    ;;
esac

case $PHP_VERSION in
  8.6*)
    php -m | grep -q '^imagick$' || docker-php-ext-enable imagick
    ;;
  *)
    docker-php-ext-enable imagick
    ;;
esac

case $PHP_VERSION in
  8.4*|8.5*)
    apk add --no-cache krb5-dev
    # If we really need it.
    php -m | grep -q '^imap$' || yes | pecl install imap
    docker-php-ext-enable imap
    ;;
  8.6*)
    echo "Skipping imap for PHP $PHP_VERSION (ext/imap no longer bundled, and pecl is unavailable)"
    ;;
  *)
    docker-php-ext-install imap
    ;;
esac

case $PHP_VERSION in
  8.5*|8.6*)
    echo "Skipping opcache for PHP $PHP_VERSION"
    ;;
  *)
    docker-php-ext-install opcache
    ;;
esac

docker-php-ext-install gmp ldap xsl mysqli calendar gd pdo_mysql pdo_pgsql zip bcmath soap exif bz2 pcntl

case $PHP_VERSION in
  8.6*)
    echo "rdkafka and apcu were already enabled by pie for PHP $PHP_VERSION"
    ;;
  *)
    docker-php-ext-enable rdkafka apcu
    ;;
esac

mkdir ~/.ssh/
ssh-keyscan -t rsa git.drupal.org >> ~/.ssh/known_hosts
ssh-keyscan -t rsa gitlab.com >> ~/.ssh/known_hosts
ssh-keyscan -t rsa bitbucket.org >> ~/.ssh/known_hosts
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

git clone https://github.com/FriendsOfPHP/security-advisories /root/.symfony/cache/security-advisories
git clone https://github.com/violinist-dev/drupal-contrib-sa /root/drupal-contrib-sa

machine=`uname -m 2>/dev/null || /usr/bin/uname -m`
case ${machine} in
  arm|armv7*)
    machine="arm"
    ;;
  aarch64*|armv8*)
    machine="arm64"
    ;;
  i386)
    machine="386"
    ;;
  x86_64)
    machine="amd64"
    ;;
  *)
    output "  [ ] You architecture (${machine}) is not currently supported" "error"
    exit 1
    ;;
esac

wget https://github.com/symfony/cli/releases/download/v4.16.3/symfony_linux_${machine}.gz -O /tmp/symfony.gz
gzip -d /tmp/symfony.gz
chmod 755 /tmp/symfony
mv /tmp/symfony /usr/local/bin/symfony
wget https://getcomposer.org/download/latest-2.2.x/composer.phar -O /tmp/composer22
chmod 755 /tmp/composer22
mv /tmp/composer22 /usr/local/bin/composer22
