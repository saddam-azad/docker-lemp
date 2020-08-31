#####################################
#                                   #
#           Webserver               #
#                                   #
#####################################
FROM alpine:edge

## Install packages
RUN (echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories) \
    && apk update \
    && apk upgrade \
    # Basic tools
    && apk add --virtual .system \
        git curl wget bash nano openrc shadow \
        ca-certificates mariadb-client mysql-client \
    # Nginx
    && apk add -virtual .nginx \
        nginx gettext \
    # PHP 7 and Extensions
    && apk add --virtual .php \
        php7 \
        php7-session \
        php7-ctype \
        php7-fpm \
        php7-json \
        php7-iconv \
        php7-phar \
        php7-dom \
        php7-bcmath \
        php7-curl \
        php7-fileinfo \
        php7-mbstring \
        php7-mysqli \
        php7-xml \
        php7-tokenizer \
        php7-opcache \
        php7-simplexml \
        php7-xmlwriter \
        php7-openssl \
        php7-gd

## Install composer
RUN (curl --fail -sS https://getcomposer.org/installer | php) && \
    chmod +x composer.phar && \
    mv composer.phar /usr/bin/composer && \
    composer -V

## Install wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \ 
    && wp cli version --allow-root

## ensure www-data user/group exists and running at PID/GID 82
RUN set -x ; \
    addgroup -g 82 -S www-data ; \
    adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1 && \
    usermod -G www-data nginx

## Get the Nginx Configs and replace the default
RUN rm -Rf /etc/nginx && \ 
    git clone https://github.com/saddam-azad/nginx-configs.git /etc/nginx

## Override the default PHP configs
COPY ./php/php.config.ini /etc/php7/conf.d/php.config.ini
COPY ./php/www.config.conf /etc/php7/php-fpm.d/www.config.conf

## Ensuring nginx has permission over directories
RUN chown -R www-data:www-data /var/lib/nginx/ && \
## Delete the APK cache
    rm -rf /var/cache/apk/*

# Copy in scripts for certbot
COPY ./scripts/ /scripts
RUN chmod +x /scripts/*.sh

VOLUME ["/var/cache/nginx"]
EXPOSE 80 443

CMD ["/bin/bash", "/scripts/entrypoint.sh"]