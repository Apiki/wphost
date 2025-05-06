FROM openresty/openresty:1.27.1.2-0-bookworm-fat as builder

ENV DEBIAN_FRONTEND noninteractive
ENV NGINX_PATH /usr/local/openresty/nginx/conf
ENV OPENRESTY_VERSION 1.27.1.2
ENV OPEN_SSL 3.5.0
ENV CFLAGS "-O2"
ENV LDFLAGS "-Wl,-s"

# Instalar dependências necessárias para compilação
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreadline-dev \
    libncurses5-dev \
    libpcre3-dev \
    libssl-dev \
    perl \
    make \
    build-essential \
    git \
    wget \
    zlib1g-dev \
    libpcre3 \
    unzip \
    curl \
    uuid-dev \
    cmake \
    libmaxminddb-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar CMake mais recente
RUN wget -O cmake.sh https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-linux-$(uname -m).sh \
    && chmod +x cmake.sh \
    && ./cmake.sh --skip-license --prefix=/usr \
    && rm cmake.sh

# Baixar e extrair OpenResty e OpenSSL
RUN wget https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz \
    && tar -xzf openresty-${OPENRESTY_VERSION}.tar.gz \
    && wget https://github.com/openssl/openssl/releases/download/openssl-${OPEN_SSL}/openssl-${OPEN_SSL}.tar.gz \
    && tar -xzf openssl-${OPEN_SSL}.tar.gz \
    && rm *.tar.gz

# Compilar OpenSSL primeiro
RUN cd /openssl-${OPEN_SSL} \
    && ./config --prefix=/openssl-${OPEN_SSL}/.openssl no-shared no-threads -g \
    && make \
    && make install_sw LIBDIR=lib

# Clonar e compilar módulos
RUN cd /openresty-${OPENRESTY_VERSION} \
    && git clone --depth 1 https://github.com/FRiCKLE/ngx_cache_purge.git ngx_cache_purge-2.3 \
    && git clone --depth 1 https://github.com/vozlt/nginx-module-vts.git \
    && git clone --depth 1 https://salsa.debian.org/nginx-team/libnginx-mod-http-geoip2.git libnginx-mod-http-geoip2 \
    && git clone --depth 1 --recurse-submodules -j8 https://github.com/google/ngx_brotli \
    && cd ngx_brotli/deps/brotli \
    && mkdir out && cd out \
    && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-O2" -DCMAKE_CXX_FLAGS="-O2" -DCMAKE_INSTALL_PREFIX=./installed .. \
    && cmake --build . --config Release --target brotlienc

# Compilar OpenResty
RUN cd /openresty-${OPENRESTY_VERSION} \
    && ./configure \
    --add-module=/openresty-${OPENRESTY_VERSION}/ngx_cache_purge-2.3 \
    --add-module=/openresty-${OPENRESTY_VERSION}/nginx-module-vts \
    --add-module=/openresty-${OPENRESTY_VERSION}/ngx_brotli \
    --add-dynamic-module=/openresty-${OPENRESTY_VERSION}/libnginx-mod-http-geoip2 \
    --with-http_stub_status_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-openssl=/openssl-${OPEN_SSL} \
    --with-ipv6 \
    --with-http_realip_module \
    && make -j$(nproc) \
    && make install

# Imagem final
FROM openresty/openresty:1.27.1.2-0-bookworm-fat

# Instalar dependências necessárias
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpcre3 \
    libpcre3-dev \
    libssl3 \
    libssl-dev \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Copiar arquivos compilados do builder
COPY --from=builder /usr/local/openresty/ /usr/local/openresty/

# Configurar logs
RUN ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
    && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log \
    && ln -s /usr/local/openresty/nginx/sbin/nginx /usr/bin/nginx

EXPOSE 80 443

WORKDIR $NGINX_PATH/
CMD ["/usr/local/openresty/nginx/sbin/nginx", "-g", "daemon off;"]