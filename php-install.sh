set -eu

apk add --no-cache imap-dev sudo git libpng libjpeg libpq libxml2 mysql-client openssh-client rsync patch bash imagemagick libzip-dev \
    imagemagick-libs imagemagick-dev autoconf g++ make icu-dev libpng-dev libjpeg-turbo-dev postgresql-dev libxml2-dev bzip2-dev icu icu-dev $PHPIZE_DEPS

if [ $PHP_VERSION = "8.0" ]
then
    docker-php-ext-install zip
    wget https://github.com/FriendsOfPHP/pickle/releases/download/v0.6.0/pickle.phar && mv pickle.phar /usr/local/bin/pickle
    chmod +x /usr/local/bin/pickle
    pickle install igbinary
    pickle install apcu
    echo -e "no\nno\nno\nno\nno\nno" | pickle install mongodb
    pickle install imagick
    mkdir -p /usr/src/php/ext/redis && curl -fsSL https://pecl.php.net/get/redis | tar xvz -C "/usr/src/php/ext/redis" --strip 1 && docker-php-ext-install redis
else
    pecl install igbinary
    yes | pecl install apcu mongodb imagick redis-3.1.1
fi

docker-php-ext-configure intl
docker-php-ext-install intl
docker-php-ext-enable intl
if [ $PHP_VERSION = "7.4" ] || [ $PHP_VERSION = "8.0" ]
then
    apk add --no-cache oniguruma-dev
    docker-php-ext-configure gd --with-jpeg=/usr
else
    docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr
fi
docker-php-ext-install imap gd mbstring pdo_mysql pdo_pgsql zip opcache bcmath soap exif bz2 pcntl intl
if [ $PHP_VERSION = "8.0" ]
then
    docker-php-ext-enable apcu redis exif gd
else
    docker-php-ext-enable apcu mongodb imagick redis exif gd
fi

curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer

composer self-update --1
composer global require hirak/prestissimo

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
