# 📋 CHANGELOG — apiki/wphost

Histórico de versões das imagens Docker do Apiki Host.
Formato da tag: `<serviço>-<versão>`. O **Docker Hub** é a fonte de verdade do que está publicado ([apiki/wphost](https://hub.docker.com/repository/docker/apiki/wphost/general)); nem todo release antigo tem tag git correspondente.

Para o processo de atualização, veja [MAINTAINING.md](MAINTAINING.md).

---

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
