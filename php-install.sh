set -eu

apk add --no-cache unixodbc-dev gmp-dev yaml-dev ldb-dev libldap openldap-dev pcre-dev libxslt-dev imap-dev sudo git libpng libjpeg libpq libxml2 mysql-client openssh-client rsync patch bash imagemagick libzip-dev \
    imagemagick-libs imagemagick-dev librdkafka-dev autoconf g++ make icu-dev libpng-dev libjpeg-turbo-dev postgresql-dev libxml2-dev bzip2-dev icu icu-dev libmemcached-dev linux-headers $PHPIZE_DEPS

case $PHP_VERSION in
  8.3|8.2|8.1) 
    apk add --no-cache mpdecimal-dev
    ;;
  *)     
    wget https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-2.5.1.tar.gz
    tar -xvzf mpdecimal-2.5.1.tar.gz
    cd mpdecimal-2.5.1
    ./configure --disable-cxx
    make
    make install
    cd ..
    rm -rf mpdecimal-2.5.1*
    ;;
esac

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


yes | pecl install oauth apcu igbinary rdkafka yaml decimal uuid msgpack

case $PHP_VERSION in
  8.4*)
    echo "Installing mailparse from source"
    git clone https://github.com/php/pecl-mail-mailparse
    cd pecl-mail-mailparse
    phpize
    ./configure
    make
    make install
    cd -
    ;;
  *)
    yes | pecl install mailparse
    ;;
esac

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

case $PHP_VERSION in
  8.4*)
    echo "skipping redis for PHP 8.4"
    ;;
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
docker-php-ext-install intl sockets
docker-php-ext-enable intl yaml sqlsrv pdo_sqlsrv decimal uuid mailparse msgpack sockets oauth

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

case $PHP_VERSION in
  8.4*)
    echo "skipping imagick on PHP 8.4"
    ;;
  8.3) 
    curl -fL -o imagick.tgz 'https://pecl.php.net/get/imagick-3.7.0.tgz'; \
	echo '5a364354109029d224bcbb2e82e15b248be9b641227f45e63425c06531792d3e *imagick.tgz' | sha256sum -c -; \
	tar --extract --directory /tmp --file imagick.tgz imagick-3.7.0; \
	grep '^//#endif$' /tmp/imagick-3.7.0/Imagick.stub.php; \
	test "$(grep -c '^//#endif$' /tmp/imagick-3.7.0/Imagick.stub.php)" = '1'; \
	sed -i -e 's!^//#endif$!#endif!' /tmp/imagick-3.7.0/Imagick.stub.php; \
	grep '^//#endif$' /tmp/imagick-3.7.0/Imagick.stub.php && exit 1 || :; \
	docker-php-ext-install /tmp/imagick-3.7.0; \
	rm -rf imagick.tgz /tmp/imagick-3.7.0; \
    docker-php-ext-enable imagick
    ;;
  *)     
    yes | pecl install imagick
    docker-php-ext-enable imagick
    ;;
esac

case $PHP_VERSION in
  8.4*)
    apk add --no-cache krb5-dev
    yes | pecl install imap
    docker-php-ext-enable imap
    ;;
  *)
    docker-php-ext-install imap
    ;;
esac

docker-php-ext-install gmp ldap xsl mysqli xml calendar gd mbstring pdo_mysql pdo_pgsql zip opcache bcmath soap exif bz2 pcntl
docker-php-ext-enable ldap rdkafka calendar memcached mongodb apcu exif gd

curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer

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
