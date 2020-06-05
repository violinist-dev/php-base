

composer self-update \
    && composer global require hirak/prestissimo \
    && apk add --no-cache imagemagick imagemagick-libs imagemagick-dev autoconf bzip2-dev g++ make icu-dev \
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
    && git clone https://github.com/violinist-dev/drupal-contrib-sa /root/drupal-contrib-sa \
    && wget https://get.symfony.com/cli/v4.5.4/symfony_linux_amd64 -O /tmp/symfony.gz \
    && gzip -d /tmp/symfony.gz \
    && chmod 755 /tmp/symfony \
    && mv /tmp/symfony /usr/local/bin/symfony \
