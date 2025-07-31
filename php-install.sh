set -eu

apk add --no-cache unixodbc-dev brotli-dev gmp-dev yaml-dev samba-dev libldap openldap-dev pcre-dev libxslt-dev imap-dev sudo git libpng libjpeg libpq libxml2 mysql-client openssh-client rsync patch bash imagemagick libzip-dev \
    imagemagick-libs unixodbc-dev mpdecimal-dev gettext gettext-dev imagemagick-dev librdkafka-dev autoconf g++ make icu-dev libpng-dev libjpeg-turbo-dev postgresql-dev libxml2-dev bzip2-dev icu icu-dev libmemcached-dev linux-headers $PHPIZE_DEPS

pecl channel-update pecl.php.net

case $PHP_VERSION in
  7.3)
    yes | pecl install mongodb-1.16.2
    ;;
  7.4|8.0)
    echo "yes" | pecl install mongodb-1.20.1
    ;;
  8.5*)
    echo "Skipping mongo db driver for PHP $PHP_VERSION"
    ;;
  *)
    echo "yes" | pecl install mongodb
    ;;
esac

case $PHP_VERSION in
  8.5*)
    echo "Skipping mongodb for PHP $PHP_VERSION"
    ;;
  *)
    docker-php-ext-enable mongodb
    ;;
esac

case $PHP_VERSION in
  7.*|8.0*|8.5*)
    echo "Skipping swoole for PHP $PHP_VERSION"
    ;;
  *)
    echo "" | pecl install swoole 
    docker-php-ext-enable swoole
    ;;
esac

yes | pecl install apcu igbinary rdkafka yaml decimal uuid msgpack mailparse

case $PHP_VERSION in
  8.5*)
    echo "Skipping oauth extension for $PHP_VERSION"
    ;;
  *)
    yes | pecl install oauth
    ;;
esac

case $PHP_VERSION in
  8.5*)
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
  8.5*)
    echo "Skipping sqlsrv on $PHP_VERSION"
    ;;
  *)
    yes | pecl install sqlsrv pdo_sqlsrv
    ;;
esac

case $PHP_VERSION in
  8.*) 
    mkdir -p /usr/src/php/ext/redis && curl -fsSL https://pecl.php.net/get/redis | tar xvz -C "/usr/src/php/ext/redis" --strip 1 && docker-php-ext-install redis
    docker-php-ext-enable redis
    ;;
  *)     
    yes | pecl install redis-3.1.1
    docker-php-ext-enable redis
    ;;
esac

docker-php-ext-configure intl
docker-php-ext-configure gettext
docker-php-ext-install intl gettext sockets
docker-php-ext-enable intl yaml decimal uuid mailparse msgpack sockets

case $PHP_VERSION in
  8.5*)
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
    docker-php-ext-enable ftp
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

yes | pecl install imagick
docker-php-ext-enable imagick

case $PHP_VERSION in
  8.4*|8.5*)
    apk add --no-cache krb5-dev
    yes | pecl install imap
    docker-php-ext-enable imap
    ;;
  *)
    docker-php-ext-install imap
    ;;
esac

docker-php-ext-install gmp ldap xsl mysqli xml calendar gd mbstring pdo_mysql pdo_pgsql zip opcache bcmath soap exif bz2 pcntl
docker-php-ext-enable ldap rdkafka calendar apcu exif gd

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
