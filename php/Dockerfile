FROM php:7.4.21-fpm-alpine3.13
MAINTAINER mesaque.silva@apiki.com

RUN apk update && \
	apk upgrade && \
	apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev libxml2-dev curl-dev  libmcrypt-dev libpq cyrus-sasl-dev libzip libzip-dev libmemcached-dev msmtp pcre-dev zlib-dev git zip bash vim sudo bind-tools libsodium-dev libssh2-dev imagemagick-dev libmcrypt-dev && \
  docker-php-ext-configure gd --with-freetype --with-jpeg && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  docker-php-ext-install -j${NPROC} gd && \
  apk del --no-cache freetype-dev libpng-dev libjpeg-turbo-dev

RUN apk add --no-cache $PHPIZE_DEPS

RUN cd /tmp \
    && git clone https://git.php.net/repository/pecl/networking/ssh2.git && cd /tmp/ssh2 \
    && phpize && ./configure && make && make install

RUN echo '' | pecl install -f memcached
RUN echo '' | pecl install -f imagick
RUN echo '' | pecl install -f mcrypt
RUN echo '' | pecl install -f redis
RUN pecl install -f libsodium

RUN cd /usr/bin && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && mv /usr/bin/wp-cli.phar /usr/bin/wp && chmod +x /usr/bin/wp

RUN docker-php-ext-install zip mysqli sockets soap calendar bcmath opcache exif iconv ftp
RUN docker-php-ext-enable redis ssh2 imagick mcrypt memcached

RUN deluser www-data && deluser xfs
RUN echo "www-data:x:33:33:Apiki WP Host,,,:/var/www:/bin/false" >> /etc/passwd && echo "www-data:x:33:www-data" >> /etc/group
WORKDIR /var/www
USER www-data
