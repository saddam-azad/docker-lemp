FROM php:8.0.2-fpm-alpine AS build

## Install Nginx 
#   and everything else to run a functioning webserver
RUN (echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories) \
    && apk update \
    && apk upgrade \
    # Basic tools
    && apk add --virtual .system \
        git curl wget bash nano openrc shadow gnupg \
        ca-certificates supervisor lvm2 gettext \
    # DB
    && apk add --virtual .db \
        mariadb-client mysql-client
    # Nginx
    # && apk add --virtual .nginx \
    #     nginx  

RUN set -ex ; \
    addgroup -S nginx ; \
    adduser \
        -D \
        -S \
        -h /var/cache/nginx \
        -s /sbin/nologin \
        -G nginx \
        nginx ;

ENV NAXSI_VERSION=1.3 \
    NGINX_VERSION=1.18.0 \
    PURGE_VERSION=2.3

WORKDIR /tmp

RUN set -ex ; \
    curl \
        -fSL \
        http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
        -o nginx.tar.gz \
    ; \
    curl \
        -fSL \
        https://github.com/nbs-system/naxsi/archive/$NAXSI_VERSION.tar.gz \
        -o naxsi.tar.gz \
    ; \
    curl \
        -fSL \
        http://labs.frickle.com/files/ngx_cache_purge-$PURGE_VERSION.tar.gz \
        -o purge.tar.gz \
    ;

RUN set -ex ; \
    apk add --no-cache --virtual .build-deps \
        clang \
        gcc \
        gd-dev \
        geoip-dev \
        gettext \
        libc-dev \
        libxslt-dev \
        linux-headers \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
    ; \
    \
    tar -xzf naxsi.tar.gz ; \
    tar -xzf nginx.tar.gz ; \
    tar -xzf purge.tar.gz ; 
    # \
    # rm \
    #     naxsi.tar.gz \
    #     nginx.tar.gz \
    #     purge.tar.gz \
    # ;

RUN set -ex ; \
    config=" \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --add-module=/tmp/naxsi-$NAXSI_VERSION/naxsi_src/ \
        --add-module=/tmp/ngx_cache_purge-$PURGE_VERSION/ \
        --with-http_ssl_module \
        --with-pcre \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_xslt_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-http_geoip_module=dynamic \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-stream_realip_module \
        --with-stream_geoip_module=dynamic \
        --with-http_slice_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-compat \
        --with-file-aio \
        --with-http_v2_module \
        " \
    ; \
    \
    cd nginx-$NGINX_VERSION ; \
    CC=clang CFLAGS="-pipe -O" ./configure $config ; \
    make -j$(getconf _NPROCESSORS_ONLN) ; \
    make install ; \
    rm -rf /etc/nginx/html/ ; \
    mkdir /etc/nginx/conf.d/ ; \
    mkdir -p /usr/share/nginx/html/ ; \
    install -m644 \
        ../naxsi-$NAXSI_VERSION/naxsi_config/naxsi_core.rules \
        /etc/nginx \
    ; \
    # install -m644 html/index.html /usr/share/nginx/html/ ; \
    # install -m644 html/50x.html /usr/share/nginx/html/ ; \
    ln -s ../../usr/lib/nginx/modules /etc/nginx/modules ; \
    strip /usr/sbin/nginx* ; \
    strip /usr/lib/nginx/modules/*.so ; \
    \
    rm -rf \
        /tmp/naxsi-$NAXSI_VERSION \
        /tmp/nginx-$NGINX_VERSION \
    ; \
    \
    mv /usr/bin/envsubst /tmp/ ; \
    \
    run_deps="$( \
        scanelf \
                --needed \
                --nobanner \
                /usr/sbin/nginx \
                /usr/lib/nginx/modules/*.so \
                /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
        )" \
    ; \
    apk add --no-cache --virtual .nginx-run-deps $run_deps ; \
    apk del .build-deps ; \
    mv /tmp/envsubst /usr/local/bin/ ; \
    \
    ln -sf /dev/stdout /var/log/nginx/access.log ; \
    ln -sf /dev/stderr /var/log/nginx/error.log ;

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
RUN chown -R www-data:www-data /var/www/html/ && \
## Delete the APK cache
    rm -rf /var/cache/apk/*

# Configure supervisord
COPY ./config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
