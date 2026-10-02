# 📋 CHANGELOG — apiki/wphost

Histórico de versões das imagens Docker do Apiki Host.
Formato da tag: `<serviço>-<versão>`. O **Docker Hub** é a fonte de verdade do que está publicado ([apiki/wphost](https://hub.docker.com/repository/docker/apiki/wphost/general)); nem todo release antigo tem tag git correspondente.

Para o processo de atualização, veja [MAINTAINING.md](MAINTAINING.md).

---

## 2026-10-02

### `waf-4.29.1` — HTTP/3 passa a entregar o header `Host` (patch no nginx)
Mesmo nginx 1.30.5 / ModSecurity 3.0.17 / conector 1.0.4 / OpenSSL 3.5.9 do `waf-4.29.0`; muda SO o patch abaixo. O `.1` e revisao da imagem, nao do CRS (o clone interno segue `v4.29.0` e e inerte; a frota usa o CRS do `webserver.tgz`).

- **Problema**: em HTTP/3 o cliente manda `:authority`, nao `Host` (RFC 9114 4.3.1). O modulo h2 do nginx sintetiza a linha `Host` ("compatibility for $http_host"); o h3 nao. Resultado: `$http_host` vazio nos logs e o ModSecurity sem `Host` -> CRS 920280 em TODA requisicao h3 (CRITICAL no CRS 4.29 = 403) e 920350 (Host = IP) cego. Upstream: nginx trac #2659 fechado como "esperado"; ModSecurity-nginx PR #364 aberto.
- **Correcao**: `waf/patches/nginx-http3-host.patch` (aplicado com `patch -p1` no build): em `ngx_http_v3_process_request_header`, sem `Host` e com `:authority`, chama `ngx_http_v3_construct_host_header()` (copia do equivalente h2). O caso Host x `:authority` divergente continua dando 400 como antes. Sem segundo lookup de vhost (`ngx_http_process_host` sai cedo se o server ja foi resolvido).
- **Validado**: A/B local com CRS 4.29 completo (imagem velha h3 = 403/920280; nova = 200, `$http_host` preenchido, 920350 volta igual ao HTTP/1.1); canario em producao no felipebazon.com (OCI) em 2026-10-02 com h3 ligado, zero 920280, dominio logado em linhas HTTP/3.0, SEM nenhuma exclusao de regra.
- Publicada primeiro como `wafrc-4.29.0-h3host` e promovida por `docker buildx imagetools create -t apiki/wphost:waf-4.29.1 apiki/wphost:wafrc-4.29.0-h3host` (digest `f4a99d1a`, amd64+arm64). A role `lightsail` passa a usar esta tag em host novo.
- **Manutencao**: o patch tem que ser reaplicado a cada bump de nginx (ver MAINTAINING, armadilha 13).

## 2026-10-01

### `waf-4.29.0` — motor ModSecurity 3.0.17 + HTTP/3 (nginx 1.30.5)
Tag mantem a sintaxe `waf-<versao do CRS>`, mas o valor desta imagem esta no **motor**, nao nas regras: a frota carrega o CRS do `webserver.tgz` (`/etc/nginx/owasp-crs` + `rules/` do host), nao do clone `/coreruleset` da imagem (que nada referencia).

- nginx 1.30.4 → **1.30.5** (stable), com **`--with-http_v3_module`** novo (QUIC nativo via OpenSSL ≥ 3.5.1; sem quictls/BoringSSL).
- ModSecurity v3.0.16 → **v3.0.17** (2026-09-29): 7 GHSA, inclui bypass de inspecao de response body por `Content-Type` em caixa mista, `htmlEntityDecode`, `base64DecodeExt` URL-safe, ponteiro nao inicializado no XML, nullptr em `@rx`, `filename*` em multipart.
- ModSecurity-nginx: antes clonado de `master` sem pino; agora **pinado em v1.0.4** (`ENV ModSecurity_Nginx_Version`).
- OpenSSL 3.5.7 → **3.5.9** (LTS). CRS do clone interno v4.28.0 → v4.29.0 (so `ENV OWASP_RULES`).
- URLs dos repositorios trocadas de `SpiderLabs/*` para `owasp-modsecurity/*` (redirect do GitHub; evita depender dele).
- Base continua `debian:bookworm-slim` (trixie exigiria PCRE2 no ModSecurity; adiado).
- Publicada primeiro como `wafrc-4.29.0` (canario; o nome NAO casa com o `grep waf-` da role `lightsail`, que escolhe a maior tag `waf-*` para host novo) e promovida por `docker buildx imagetools create -t apiki/wphost:waf-4.29.0 apiki/wphost:wafrc-4.29.0`.
- Validado: amd64+arm64 no Hub (digest `62caf13e`); smoke `nginx -V` = nginx/1.30.5, OpenSSL 3.5.9, `http_v2`+`http_v3`+brotli; `nginx -t` limpo com a config e o CRS 3.1.0 reais do apiki.com; canario em producao no apiki.com (OCI, 163.176.213.149) em 2026-10-01 16:33 -03:00 com ~1-2 s de indisponibilidade no `up -d`, headers de seguranca identicos ao baseline, ModSecurity-nginx v1.0.4 + libmodsecurity 3.0.17 carregando 818 regras; HTTP/3 ligado no mesmo host as 16:35 e validado pela internet (GET/POST/403/401 em `proto=3`, upgrade h2->h3 por Alt-Svc). E2E previo em Docker local: ModSecurity bloqueia igual em h2 e h3 (403 GET e POST).
- Tag git `waf-4.29.0` (commit do release: `git rev-parse waf-4.29.0^{}`); tag Docker Hub `waf-4.29.0` = digest `62caf13e`.
- **HTTP/3 na frota NAO esta ligado por esta imagem**: exige `listen 443 quic reuseport;` (uma vez por endereco, no `00-default`), `listen 443 quic;` nos demais, `add_header Alt-Svc 'h3=":443"; ma=86400' always;` TAMBEM dentro de `location /` (o `add_header Cache-Control` ali descarta os do server — hoje HSTS/X-Frame ja nao saem no HTML por isso), `firewall-cmd --add-port=443/udp` e UDP/443 em NSG/SG/Lightsail. Rollout em sessao separada.

## 2026-07-20

### `php-8.5.8` — re-release: faxina de temporarios orfaos do ImageMagick
Republicacao da tag `php-8.5.8` no Docker Hub (mesma versao de PHP/extensoes; conteudo sobrescrito) corrigindo um vazamento **sistemico da imagem** que enchia o disco do host.

- **Causa (na imagem, nao no site):** ImageMagick sem limite de disco/temp + `/tmp` na camada gravavel do container + php-fpm matando/reciclando workers (`request_terminate_timeout=180s`, `pm.max_requests=500`) + **nenhum faxineiro de `/tmp`** -> arquivos `magick-*` orfaos (deixados quando o worker morre no meio da conversao) acumulam indefinidamente. Incidente de referencia: `pingback.com` (22,5 GB em 376 `magick-*`, disco a 95%).
- **Fix (somente no `Dockerfile-8`):**
  1. **Entrypoint auto-faxina** (`/usr/local/bin/apiki-entrypoint.sh`): remove `magick-*` no start e, em background, a cada 5 min os ociosos ha +15 min (worker morre em <=180s, entao +15 min nunca e conversao viva); encadeia no `docker-php-entrypoint` mantendo php-fpm como PID 1.
  2. **Cap de disco do ImageMagick** no `policy.xml` do runtime stage: `<policy domain="resource" name="disk" value="2GiB"/>`.
- Build local multi-arch (amd64 + arm64) com `--push`, sobrescrevendo a tag. Validado: PHP 8.5.8, extensoes carregadas, WP-CLI 2.12.0, entrypoint varrendo `/tmp`, cap ativo na policy. Tag git `php-8.5.8` reapontada para o novo commit.

## 2026-07-17

Atualização das imagens principais para o latest estável, com build local multi-arch (amd64 + arm64) e publicação no Docker Hub.

### `php-8.5.8` — PHP 8.4.12 → 8.5.8
- Base `php:8.5.8-fpm-alpine3.24` (era `8.4.12-fpm-alpine3.22`).
- Extensões PECL: **redis** 6.1.0 → 6.3.0, **imagick** 3.8.0 → 3.8.1, **memcached** 3.2.0 → 3.4.0. libsodium 2.0.23 (já era latest).
- **Fix necessário:** removido `opcache` do `docker-php-ext-install` — no PHP ≥ 8.5 o OPcache é estático no binário e não pode ser instalado como extensão compartilhada (o build falhava com `cp: can't stat 'modules/*'`). As diretivas `opcache.*` do `.ini` seguem válidas.
- Validado: PHP 8.5.8 NTS, todas as extensões carregadas (redis, imagick, memcached, apcu, igbinary, ssh2, gd, intl, sodium, opcache…), New Relic instalado, WP-CLI 2.12.0, usuário `www-data` uid 33.
- Commit `1cf9bc2` · tag `php-8.5.8`.

### `nginx-1.31.1.1` — OpenResty 1.27.1.2 → 1.31.1.1
- Base `openresty/openresty:1.31.1.1-2-bookworm-fat`.
- OpenSSL 3.5.0 → 3.5.7 (branch LTS).
- Só o `nginx/all/Dockerfile` foi atualizado (os variantes `amd64`/`amr64` são legados).
- Validado: OpenResty 1.31.1.1 com OpenSSL 3.5.7, módulos http_v3, brotli, geoip2, vts, cache_purge, realip; `nginx -t` OK.
- Commit `9d057f1` · tag `nginx-1.31.1.1`.

### `waf-4.28.0` — CRS 4.13.0 → 4.28.0
- nginx 1.28.0 → **1.30.4** (branch stable), ModSecurity v3.0.14 → **v3.0.16**, OWASP CRS v4.13.0 → **v4.28.0**, OpenSSL 3.5.0 → 3.5.7.
- **Migração de base:** `debian:buster-slim` → `debian:bookworm-slim` (buster EOL, fora dos espelhos). Ajustes de pacote: removido `zlibc`, `libpcre++-dev` → `libpcre2-dev` + `libpcre2-8-0`.
- **Fix necessário:** clone do ModSecurity mudado para `git submodule update --init --recursive` (o mbedtls tem submódulos aninhados; sem `--recursive` o `configure` falhava com "Mbed TLS was not found").
- Validado: nginx 1.30.4, `libmodsecurity.so.3.0.16`, CRS v4.28.0, módulo ModSecurity carrega em `nginx -t`.
- Commit `2c5e8f6` · tag `waf-4.28.0`.

---

## Histórico anterior (por tag git)

| Data | Tag |
|---|---|
| 2025-05-06 | `nginx-1.27.1.2` |
| 2025-04-30 | `waf-4.13.0` |
| 2025-04-28 | `nginx-1.25.3.1` |
| 2023-10-30 | `nginx-1.21.4.2` |
| 2023-08-11 | `crowdsecbouncer-0.0.17-rc5` |
| 2023-03-15 | `nginx-1.21.4.1`, `waf-3.3.4` |
| 2023-03-14 | `php-8.2.3`, `php-7.4.33` |
| 2022-06-20 | `php-7.4.30` |
| 2022-05-09 | `php-8.1.5` |
| 2021-12-23 | `php-7.4.27` |

> Publicados no Hub mas **sem tag git**: `php-8.4.12` (2025-09), `php-8.3.15` (2025-01), `php-8.3.13`, `php-8.3.11`, `php-8.3.10`, `php-7.4.34[-newrelic]`, `php-8.2.13`, `pgbackup-v1` (2026-01), entre outros. Ver a lista completa no Docker Hub.
