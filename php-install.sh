set -eu

apk add --no-cache --virtual .dd-build-deps libpng-dev libjpeg-turbo-dev postgresql-dev libxml2-dev $PHPIZE_DEPS \
  && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
  && docker-php-ext-install gd mbstring pdo_mysql pdo_pgsql zip \
  && docker-php-ext-install opcache bcmath soap \
  && pecl install redis-3.1.1 \
  && docker-php-ext-enable redis \
  && apk add --no-cache sudo git libpng libjpeg libpq libxml2 mysql-client openssh-client rsync patch bash imagemagick \
    imagemagick-libs imagemagick-dev autoconf bzip2-dev g++ make icu-dev \
  && apk del .dd-build-deps

curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/local/bin/composer

composer self-update \
    && composer global require hirak/prestissimo \
    && yes | pecl install apcu mongodb imagick \
    && docker-php-ext-configure intl --enable-intl \
    && docker-php-ext-install exif bz2 pcntl intl \
    && docker-php-ext-enable apcu intl mongodb imagick \
    && mkdir ~/.ssh/ \
    && ssh-keyscan -t rsa,dsa git.drupal.org >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa gitlab.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa bitbucket.org >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa github.com >> ~/.ssh/known_hosts \
    && git clone https://github.com/FriendsOfPHP/security-advisories /root/.symfony/cache/security-advisories \
    && git clone https://github.com/violinist-dev/drupal-contrib-sa /root/drupal-contrib-sa

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

wget https://github.com/symfony/cli/releases/download/v4.16.3/symfony_linux_${machine}.gz -O /tmp/symfony.gz \
    && gzip -d /tmp/symfony.gz \
    && chmod 755 /tmp/symfony \
    && mv /tmp/symfony /usr/local/bin/symfony
