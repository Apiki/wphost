FROM openresty/openresty:1.27.1.2-0-bookworm-fat

ENV DEBIAN_FRONTEND=noninteractive \
    NGINX_PATH=/usr/local/openresty/nginx/conf \
    OPENRESTY_VERSION=1.27.1.2 \
    OPEN_SSL=3.5.0\
    CFLAGS="-march=native -mtune=native -Ofast -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" \
    LDFLAGS="-Wl,-s -Wl,-Bsymbolic -Wl,--gc-sections"

# Instala dependências e faz o download do OpenResty e OpenSSL
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential \
    git wget zlib1g-dev uuid-dev cmake libmaxminddb-dev curl unzip \
    && /usr/bin/wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz && \
    tar -xzf openresty-${OPENRESTY_VERSION}.tar.gz && \
    /usr/bin/wget https://github.com/openssl/openssl/releases/download/openssl-${OPEN_SSL}/openssl-${OPEN_SSL}.tar.gz && \
    tar -xzf openssl-${OPEN_SSL}.tar.gz && \
    cd /openresty-${OPENRESTY_VERSION} && \
    git clone https://github.com/FRiCKLE/ngx_cache_purge.git ngx_cache_purge-2.3 && \
    git clone https://github.com/vozlt/nginx-module-vts.git && \
    git clone https://salsa.debian.org/nginx-team/libnginx-mod-http-geoip2.git libnginx-mod-http-geoip2 && \
    git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli && \
    cd ngx_brotli/deps/brotli && mkdir out && cd out && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CFLAGS}" -DCMAKE_INSTALL_PREFIX=./installed .. && \
    cmake --build . --config Release --target brotlienc && \
    cd /openresty-${OPENRESTY_VERSION} && \
    /openresty-${OPENRESTY_VERSION}/configure --add-module=/openresty-${OPENRESTY_VERSION}/ngx_cache_purge-2.3 \
    --add-module=/openresty-${OPENRESTY_VERSION}/nginx-module-vts --add-module=/openresty-${OPENRESTY_VERSION}/ngx_brotli \
    --add-dynamic-module=/openresty-${OPENRESTY_VERSION}/libnginx-mod-http-geoip2 \
    --with-http_stub_status_module --with-http_v2_module --with-openssl=/openresty-${OPENRESTY_VERSION}/openssl-${OPEN_SSL} \
    --with-ipv6 --with-http_realip_module && \
    /usr/bin/make && /usr/bin/make install && \
    ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log && \
    ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log && \
    ln -s /usr/local/openresty/nginx/sbin/nginx /usr/bin/nginx && \
    rm -rf /openresty-${OPENRESTY_VERSION} /openresty-${OPENRESTY_VERSION}.tar.gz && \
    apt-get clean autoclean && apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

EXPOSE 80 443

WORKDIR $NGINX_PATH/
CMD ["/usr/local/openresty/nginx/sbin/nginx", "-g", "daemon off;"]