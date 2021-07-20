FROM debian:buster-slim

LABEL maintainer="Apiki Team Maintainers <mesaque.silva@apiki.com>"

ENV NGINX_VERSION 1.19.6
ENV OWASP_RULES 3.3.0
ENV ModSecurity_Branch v3/master
ENV OPEN_SSL 1.1.1i

RUN apt-get update && apt-get install -y --no-install-recommends bison build-essential ca-certificates curl dh-autoreconf doxygen flex gawk git iputils-ping libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev libpcre3-dev libpcre++-dev libssl-dev libtool libxml2 libxml2-dev libyajl-dev locales lua5.3-dev pkg-config wget zlib1g-dev zlibc && rm -rf /var/lib/apt/lists/* &&  apt-get clean

RUN mkdir /source && cd /source

RUN git clone https://github.com/ssdeep-project/ssdeep && cd ssdeep/ && ./bootstrap && ./configure && make && make install

RUN cd /source && git clone https://github.com/SpiderLabs/ModSecurity --branch ${ModSecurity_Branch} --depth 1
RUN cd /source/ModSecurity && git submodule init && git submodule update 

RUN cd /source/ModSecurity && sh build.sh && ./configure && make && make install

RUN cd /source/ && git clone https://github.com/SpiderLabs/ModSecurity-nginx

RUN cd /source/ && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && tar -zxvf nginx-${NGINX_VERSION}.tar.gz

RUN cd /source/ && git clone https://github.com/google/ngx_brotli && cd /source/ngx_brotli && git submodule update --init

RUN cd /source/ && wget https://www.openssl.org/source/openssl-${OPEN_SSL}.tar.gz \
&& tar -xzf openssl-${OPEN_SSL}.tar.gz 

RUN cd /source/nginx-${NGINX_VERSION} \
&& ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf \
--with-compat --with-http_realip_module \
--add-dynamic-module=/source/ModSecurity-nginx \
--add-module=/source/ngx_brotli \
--with-http_v2_module --with-http_ssl_module --with-openssl=/source/openssl-${OPEN_SSL} \
&& make modules && make && make install 

RUN rm -rf /source/ && apt-get remove --purge --auto-remove -y && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/nginx.list

RUN ldconfig

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]