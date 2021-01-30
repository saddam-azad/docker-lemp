# LEMP Webserver
# Nginx + PHP 8 on Alpine Linux
# with Composer and WP CLI
FROM alpine:edge

## Install packages
RUN (echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories) \
    && apk update \
    && apk upgrade \
    # Basic tools
    && apk add --virtual .system \
        git curl wget bash nano openrc shadow \
        ca-certificates mariadb-client mysql-client \
        supervisor \
    # Nginx
    && apk add --virtual .nginx \
        nginx gettext \
    # Redis
    && apk add redis --virtual .redis \
        redis \
    # PHP 7 and Extensions
    && apk add --virtual .php \
        php8 \
        php8-common \
        php8-fpm \
        php8-cgi \
        php8-session \
        php8-ctype \
        php8-iconv \
        php8-phar \
        php8-dom \
        php8-bcmath \
        php8-curl \
        php8-fileinfo \
        php8-mbstring \
        php8-mysqli \
        php8-xml \
        php8-tokenizer \
        php8-opcache \
        php8-simplexml \
        php8-xmlwriter \
        php8-xsl \
        php8-openssl \
        php8-sockets \
        php8-exif \
        php8-gettext \
        php8-intl \
        php8-posix \
        php8-zip \
        php8-gd \
        php8-pecl-imagick \
        php8-pecl-redis

RUN ln -s /usr/bin/php8 /usr/bin/php

## Install composer and WP CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

## ensure www-data user/group exists and running at PID/GID 82
RUN set -x ; \
    addgroup -g 82 -S www-data ; \
    adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1 && \
    usermod -G www-data nginx

## Override the default PHP configs
COPY ./php/php.ini /etc/php8/conf.d/30-custom.ini
COPY ./php/fpm.conf /etc/php8/php-fpm.d/www.custom.conf

# Configure supervisord
COPY ./config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

## Ensuring nginx has permission over directories
RUN chown -R www-data:www-data /var/lib/nginx/ && \
## Delete the APK cache
    rm -rf /var/cache/apk/*

VOLUME ["/var/cache/nginx"]
EXPOSE 80 443
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]