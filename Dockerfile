FROM php:8.0.2-fpm-alpine AS build

## Install Nginx 
#   and everything else to run a functioning webserver
RUN (echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories) \
    && apk update \
    && apk upgrade \
    # Basic tools
    && apk add --virtual .system \
        git curl wget bash nano openrc shadow \
        ca-certificates supervisor lvm2 \
    # DB
    && apk add --virtual .db \
        mariadb-client mysql-client \
    # Nginx
    && apk add --virtual .nginx \
        nginx gettext 

## PHP Extensions Installer
# https://github.com/mlocati/docker-php-extension-installer
#   To get list of default extensions
#   docker run --rm php:8.0.1-fpm-alpine php -m
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions \
        bcmath \
        exif \
        gd \
        gettext \
        intl \
        imagick \
        mcrypt \
        mysqli \
        opcache \
        redis \
        sockets \
        xsl \
        zip

## Install Composer and WP CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

## ensure www-data user/group exists and running at PID/GID 82
# RUN set -x ; \
#     addgroup -g 82 -S www-data ; \
#     adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1 && \
RUN usermod -G www-data nginx

## Override the default PHP configs
COPY ./php/php.ini /etc/php8/conf.d/30-custom.ini
COPY ./php/fpm.conf /etc/php8/php-fpm.d/www.custom.conf

## Ensuring nginx has permission over directories
RUN chown -R www-data:www-data /var/lib/nginx/ && \
## Delete the APK cache
    rm -rf /var/cache/apk/*

# Configure supervisord
COPY ./config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
