set -eu

apk add --no-cache unixodbc-dev gmp-dev yaml-dev ldb-dev libldap openldap-dev pcre-dev libxslt-dev imap-dev sudo git libpng libjpeg libpq libxml2 mysql-client openssh-client rsync patch bash imagemagick libzip-dev \
    imagemagick-libs imagemagick-dev librdkafka-dev autoconf g++ make icu-dev libpng-dev libjpeg-turbo-dev postgresql-dev libxml2-dev bzip2-dev icu icu-dev libmemcached-dev $PHPIZE_DEPS

if [ $PHP_VERSION = "8.1" ] || [ $PHP_VERSION = "8.2" ] || [ $PHP_VERSION = "8.3" ] 
then
    apk add --no-cache mpdecimal-dev
else
    wget https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-2.5.1.tar.gz
    tar -xvzf mpdecimal-2.5.1.tar.gz
    cd mpdecimal-2.5.1
    ./configure --disable-cxx
    make
    make install
    cd ..
    rm -rf mpdecimal-2.5.1*
fi

pecl channel-update pecl.php.net

if [ $PHP_VERSION = "7.0" ]
then
    # Use older mongodb.
    yes | pecl install mongodb-1.9.1
elif [ $PHP_VERSION = "7.1" ]
then
    # Use older mongodb.
    yes | pecl install mongodb-1.11.1
elif [ $PHP_VERSION = "7.2" ] || [ $PHP_VERSION = "7.3" ]
then
    yes | pecl install mongodb-1.16.2
else
    echo "yes" | pecl install mongodb
fi


yes | pecl install apcu igbinary oauth rdkafka yaml decimal uuid

if [ $PHP_VERSION = "7.2" ]
then
    yes | pecl install mailparse-3.1.3
elif [ $PHP_VERSION = "8.3" ]
then
    echo "Skipping mailparse for 8.3"
else
    yes | pecl install mailparse
fi

yes | pecl install imagick
docker-php-ext-enable imagick mailparse
echo "" | pecl install memcached

if [ $PHP_VERSION = "7.2" ]
then
    yes | pecl install sqlsrv-5.8.1 pdo_sqlsrv-5.8.1
elif [ $PHP_VERSION = "7.3" ] || [ $PHP_VERSION = "7.4" ]
then
    yes | pecl install sqlsrv-5.10.1 pdo_sqlsrv-5.10.1
elif [ $PHP_VERSION = "8.0" ]
then
    yes | pecl install sqlsrv-5.11.1 pdo_sqlsrv-5.11.1
else
    yes | pecl install sqlsrv pdo_sqlsrv
fi

if [ $PHP_VERSION = "8.0" ] || [ $PHP_VERSION = "8.1" ] || [ $PHP_VERSION = "8.2" ] || [ $PHP_VERSION = "8.3" ]
then
    mkdir -p /usr/src/php/ext/redis && curl -fsSL https://pecl.php.net/get/redis | tar xvz -C "/usr/src/php/ext/redis" --strip 1 && docker-php-ext-install redis
else
    yes | pecl install imagick redis-3.1.1
fi

docker-php-ext-configure intl
docker-php-ext-install intl
docker-php-ext-enable intl yaml sqlsrv pdo_sqlsrv decimal uuid
if [ $PHP_VERSION = "7.4" ] || [ $PHP_VERSION = "8.0" ] || [ $PHP_VERSION = "8.1" ] || [ $PHP_VERSION = "8.2" ] || [ $PHP_VERSION = "8.3" ]
then
    apk add --no-cache oniguruma-dev
    docker-php-ext-configure gd --with-jpeg=/usr
else
    docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr
fi

if [ $PHP_VERSION = "8.0" ] || [ $PHP_VERSION = "8.1" ] || [ $PHP_VERSION = "8.2" ] || [ $PHP_VERSION = "8.3" ]
then
    if [ $PHP_VERSION = "8.1" ] || [ $PHP_VERSION = "8.2" ] || [ $PHP_VERSION = "8.3" ] 
    then
        # Not supported yet, fails to compile
        echo "Skipping xmlrpc and sockets on PHP 8.1 / 8.2"
    else
        # XMLRPC has moved to pecl from 8.0
        pecl install pecl install xmlrpc-1.0.0RC2
        # Sockets is supported on 8.0
        docker-php-ext-install sockets
    fi
    # In fact, PHP 8.1 seems to support it now?
    if [ $PHP_VERSION = "8.1" ]
    then
        echo "installing sockets on PHP 8.1 after all"
        docker-php-ext-install sockets
    fi
else
    docker-php-ext-install xmlrpc sockets
fi


docker-php-ext-install gmp ldap xsl mysqli xml calendar imap gd mbstring pdo_mysql pdo_pgsql zip opcache bcmath soap exif bz2 pcntl intl
if [ $PHP_VERSION = "8.1" ] || [ $PHP_VERSION = "8.2" ] || [ $PHP_VERSION = "8.3" ] 
then
    # XMLRPC does not work on 8.1
    # Sockets does not work on 8.1
    docker-php-ext-enable ldap rdkafka xml calendar memcached mongodb apcu redis exif gd
else
    docker-php-ext-enable ldap rdkafka xml sockets xmlrpc calendar memcached mongodb apcu redis exif gd
fi

curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer

composer self-update --1

mkdir ~/.ssh/
ssh-keyscan -t rsa,dsa git.drupal.org >> ~/.ssh/known_hosts
ssh-keyscan -t rsa,dsa gitlab.com >> ~/.ssh/known_hosts
ssh-keyscan -t rsa,dsa bitbucket.org >> ~/.ssh/known_hosts
ssh-keyscan -t rsa,dsa github.com >> ~/.ssh/known_hosts

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
