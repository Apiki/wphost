# Fase 1: BUILD
FROM debian:buster-slim AS builder

ENV NGINX_VERSION  1.28.0
ENV OWASP_RULES v4.13.0
ENV ModSecurity_Version v3.0.14
ENV OPEN_SSL 3.5.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    bison build-essential ca-certificates curl dh-autoreconf doxygen flex gawk git iputils-ping libcurl4-gnutls-dev libexpat1-dev libgeoip-dev liblmdb-dev libpcre3-dev libpcre++-dev libssl-dev libtool libxml2 libxml2-dev libyajl-dev locales lua5.3-dev pkg-config wget zlib1g-dev zlibc \
    && rm -rf /var/lib/apt/lists/*

# Instala cmake mais recente (antes de usá-lo)
RUN wget -O cmake.sh https://github.com/Kitware/CMake/releases/download/v3.27.7/cmake-3.27.7-linux-$(uname -m).sh && \
    chmod +x cmake.sh && \
    ./cmake.sh --skip-license --prefix=/usr && \
    rm cmake.sh

# Compila ssdeep
RUN git clone https://github.com/ssdeep-project/ssdeep /source/ssdeep && \
    cd /source/ssdeep && ./bootstrap && ./configure && make && make install

# Compila ModSecurity
RUN git clone https://github.com/SpiderLabs/ModSecurity --branch ${ModSecurity_Version} --depth 1 /source/ModSecurity && \
    cd /source/ModSecurity && git submodule init && git submodule update && \
    cd /source/ModSecurity && sh build.sh && ./configure && make && make install

# Prepara fontes do nginx + módulos
RUN git clone https://github.com/SpiderLabs/ModSecurity-nginx /source/ModSecurity-nginx && \
    git clone https://github.com/google/ngx_brotli /source/ngx_brotli && \
    cd /source/ngx_brotli && git submodule update --init

# Prepara nginx + openssl
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -P /source/ && \
    tar -zxvf /source/nginx-${NGINX_VERSION}.tar.gz -C /source/ && \
    wget https://github.com/openssl/openssl/releases/download/openssl-${OPEN_SSL}/openssl-${OPEN_SSL}.tar.gz -P /source/ && \
    tar -xzf /source/openssl-${OPEN_SSL}.tar.gz -C /source/

# Constrói Brotli
RUN cd /source/ngx_brotli/deps/brotli && \
    mkdir -p out && cd out && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF .. && \
    cmake --build . --config Release

# Compila nginx com módulos
RUN cd /source/nginx-${NGINX_VERSION} && \
    ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf \
        --with-compat --with-http_realip_module --add-dynamic-module=/source/ModSecurity-nginx --add-module=/source/ngx_brotli \
        --with-http_v2_module --with-http_ssl_module --with-openssl=/source/openssl-${OPEN_SSL} && \
    make modules && make && make install

# Fase 2: RUNTIME
FROM debian:buster-slim

LABEL maintainer="Apiki Team Maintainers <mesaque.silva@apiki.com>"

ENV OWASP_RULES v4.13.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpcre3 zlib1g libxml2 libyajl2 lua5.3 libcurl4-gnutls-dev geoip-bin locales iputils-ping ca-certificates git \
    liblmdb0 liblua5.3-0 libfuzzy-dev \
    && rm -rf /var/lib/apt/lists/*

# Copia apenas o que interessa da fase de build
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /usr/lib/nginx /usr/lib/nginx
COPY --from=builder /usr/local/modsecurity/lib/libmodsecurity* /usr/local/lib/
COPY --from=builder /usr/local/bin/ssdeep /usr/local/bin/

# OWASP CRS
RUN git clone https://github.com/coreruleset/coreruleset.git --branch ${OWASP_RULES} --depth 1 /coreruleset/

RUN ldconfig

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]