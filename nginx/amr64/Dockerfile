FROM openresty/openresty:1.21.4.2-buster-fat

ENV DEBIAN_FRONTEND noninteractive
ENV NGINX_PATH /usr/local/openresty/nginx/conf
ENV OPENRESTY_VERSION 1.21.4.2
ENV OPEN_SSL 1.1.1w

RUN apt-get update \
	&& apt-get -y install libreadline-dev libncurses5-dev libpcre3-dev \
    libssl-dev perl make build-essential git wget zlib1g-dev libpcre3 unzip curl uuid-dev

RUN /usr/bin/wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz && tar -xzf openresty-${OPENRESTY_VERSION}.tar.gz
RUN cd /openresty-${OPENRESTY_VERSION} && /usr/bin/wget https://www.openssl.org/source/openssl-${OPEN_SSL}.tar.gz \
&& tar -xzf openssl-${OPEN_SSL}.tar.gz 

RUN cd /openresty-${OPENRESTY_VERSION} \
&& git clone https://github.com/FRiCKLE/ngx_cache_purge.git ngx_cache_purge-2.3 \
&& git clone https://github.com/vozlt/nginx-module-vts.git \
&& git clone https://github.com/google/ngx_brotli

RUN cd /openresty-${OPENRESTY_VERSION}/ngx_brotli && git submodule update --init

RUN cd /openresty-${OPENRESTY_VERSION} \
&& /openresty-${OPENRESTY_VERSION}/configure \
--add-module=/openresty-${OPENRESTY_VERSION}/ngx_cache_purge-2.3 \
--add-module=/openresty-${OPENRESTY_VERSION}/nginx-module-vts \
--add-module=/openresty-${OPENRESTY_VERSION}/ngx_brotli \
--with-http_stub_status_module \
--with-http_v2_module --with-openssl=/openresty-${OPENRESTY_VERSION}/openssl-${OPEN_SSL} \
--with-ipv6 \
--with-http_realip_module \
&& /usr/bin/make && /usr/bin/make install

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
	&& ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

RUN ln -s /usr/local/openresty/nginx/sbin/nginx /usr/bin/nginx

EXPOSE 80 443

RUN rm -rf /openresty-${OPENRESTY_VERSION}
RUN rm -rf /openresty-${OPENRESTY_VERSION}.tar.gz

WORKDIR $NGINX_PATH/
CMD ["/usr/local/openresty/nginx/sbin/nginx", "-g", "daemon off;"]