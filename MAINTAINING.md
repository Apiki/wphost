# 🛠️ Guia de Manutenção — apiki/wphost

Este guia descreve **como atualizar as imagens Docker** deste repositório, **o que verificar** antes/depois e as **armadilhas já conhecidas**. É o ponto de partida para quem (pessoa ou sessão de IA) vai fazer um novo release.

> Para o histórico de versões, veja [CHANGELOG.md](CHANGELOG.md).
> Para o passo a passo de build numa máquina AWS dedicada, veja [README.md](README.md). Este guia cobre o fluxo completo, inclusive **build local multi-arch** (funciona no macOS/Linux com Docker Desktop + buildx, sem precisar da instância AWS).

---

## 1. O que é este repositório

Cada subpasta é um **serviço** e gera uma imagem publicada no Docker Hub em
[`apiki/wphost`](https://hub.docker.com/repository/docker/apiki/wphost/general),
com a tag no formato **`<serviço>-<versão>`** (ex.: `php-8.5.8`, `nginx-1.31.1.1`, `waf-4.28.0`).

Essas imagens são a base de toda a stack do **Apiki Host**.

---

## 2. O fluxo de um release (visão geral)

O processo é sempre o mesmo, para qualquer serviço:

```
1. Descobrir a versão "latest estável"  (PHP, OpenResty, nginx, ModSecurity, CRS…)
2. Descobrir a latest das dependências   (extensões PECL, OpenSSL, módulos…)
3. Editar o Dockerfile do serviço        (FROM + variáveis ENV de versão)
4. Buildar multi-arch (amd64 + arm64) e dar --push para o Docker Hub
5. VALIDAR a imagem                       (php -m / nginx -V / smoke test)
6. Commit + tag git  ( git tag -a <serviço>-<versão> ) + push
```

**Regra de ouro:** só faça o commit/tag **depois** que a imagem foi buildada, enviada e validada com sucesso. A tag git deve corresponder exatamente à tag da imagem no Hub.

---

## 3. Pré-requisitos

```bash
# Docker + buildx com um builder multi-arch (docker-container).
# Verifique se já existe:
docker buildx ls
# Se não houver um builder docker-container, crie:
docker buildx create --name multiplatform-builder --driver docker-container --use
docker buildx inspect --bootstrap

# Login no Docker Hub (necessário para o --push funcionar):
docker login
```

No ambiente atual já existe o builder **`multiplatform-builder`** e o Docker Desktop está logado no Hub.

---

## 4. Como descobrir as versões "latest" (o que checar)

| Componente | Onde checar |
|---|---|
| **PHP** | `curl -s "https://www.php.net/releases/index.php?json&version=8"` → campo `version`. Cheque também `&version=8.5`, `&version=8.4`. |
| **Imagem oficial php** | tags em `library/php` no Hub — confirmar que a `X.Y.Z-fpm-alpineA.B` existe. |
| **Extensões PECL** | `curl -s https://pecl.php.net/rest/r/<ext>/latest.txt` (redis, imagick, memcached, apcu, ssh2, igbinary). Compat: `deps.<versão>.txt`. |
| **OpenResty** | tags em `openresty/openresty` no Hub — usar a `<ver>-N-bookworm-fat` mais recente. |
| **nginx** | `https://nginx.org/en/download.html` — **usar a branch _stable_** (par no segundo número: 1.28.x, 1.30.x), não a mainline. |
| **OpenSSL** | releases em `openssl/openssl` no GitHub — **manter na branch 3.5.x (LTS até 2030)**, não pular para 3.6/4.0 sem necessidade. |
| **ModSecurity** | releases em `owasp-modsecurity/ModSecurity` (v3.0.x). |
| **OWASP CRS** | releases em `coreruleset/coreruleset` (v4.x). |

Antes de buildar, **confirme que os tarballs existem** (evita descobrir no meio do build):

```bash
curl -sIL -o /dev/null -w '%{http_code}\n' "https://openresty.org/download/openresty-<ver>.tar.gz"
curl -sIL -o /dev/null -w '%{http_code}\n' "http://nginx.org/download/nginx-<ver>.tar.gz"
curl -sIL -o /dev/null -w '%{http_code}\n' "https://github.com/openssl/openssl/releases/download/openssl-<ver>/openssl-<ver>.tar.gz"
```

---

## 5. Serviços e suas dependências

| Serviço | Dockerfile | Base | Variáveis de versão a atualizar | Tag da imagem = |
|---|---|---|---|---|
| **php 8** | `php/Dockerfile-8` | `php:X.Y.Z-fpm-alpineA.B` | PHP (FROM ×2), `redis_version`, `imagick_version`, `menchaced_version`, `libsodium_version` | versão do PHP |
| **php 7** | `php/Dockerfile-7` | `php:7.4.x-fpm-alpine` | idem + `mcrypt_version` | versão do PHP |
| **nginx** | `nginx/all/Dockerfile` | `openresty/openresty:<ver>-N-bookworm-fat` | `OPENRESTY_VERSION` (FROM ×2 + ENV), `OPEN_SSL` | versão do OpenResty |
| **waf** | `waf/Dockerfile` | `debian:bookworm-slim` | `NGINX_VERSION`, `ModSecurity_Version`, `OWASP_RULES`, `OPEN_SSL` | **versão do CRS** (`OWASP_RULES`) |
| **crowdsec** | `crowdsec/Dockerfile` | `debian:stable-slim` | `CS_BOUNCER_VERSION` | versão do bouncer |
| **postgre-backup** | `postgre-backup/Dockerfile` | `alpine:3.x` | (client PG / aws-cli via apk) | `pgbackup-vN` |

> ⚠️ **Legados — NÃO atualizar sem pedido explícito:** `nginx/amd64/` e `nginx/amr64/` (OpenResty 1.21.4.2 / Debian buster, com PageSpeed), `webserver/` e `autoscaling/` (OpenResty + PageSpeed, PHP 7.4). O fluxo ativo de nginx usa **apenas `nginx/all/`**.

### Extensões PECL do PHP (o que confirmar na imagem)
`redis, imagick, memcached, igbinary, apcu, ssh2, mcrypt (php7), gd, intl, zip, mysqli, pdo_mysql, sockets, soap, calendar, bcmath, exif, shmop, sodium, opcache` + **New Relic agent** (baixado dinamicamente, `newrelic.enabled=false` por padrão) + **WP-CLI**.

### Módulos do nginx (`nginx/all`)
`ngx_cache_purge`, `nginx-module-vts`, `ngx_brotli`, `libnginx-mod-http-geoip2` (dinâmico), `http_v2`, `http_v3`, `stub_status`, `realip`, `stream` + OpenSSL estático compilado do source.

---

## 6. Passo a passo (comandos)

Exemplo genérico. Substitua `SERVICE` e `VERSION`.

```bash
cd /caminho/para/wphost

# 3. edite o Dockerfile (FROM + ENV de versão)

# 4. build multi-arch com push.  IMPORTANTE: 'set -o pipefail' — sem ele, o
#    'tee' mascara a falha do buildx e o exit code vira 0 falso.
set -o pipefail
docker buildx build --builder multiplatform-builder \
  --platform=linux/amd64,linux/arm64 \
  --tag apiki/wphost:${SERVICE}-${VERSION} \
  --push \
  -f ${SERVICE}/Dockerfile . 2>&1 | tee build.log

# 5. confirme que a imagem multi-arch está no Hub:
docker buildx imagetools inspect apiki/wphost:${SERVICE}-${VERSION}

# 6. valide (ver seção 7), depois:
git add ${SERVICE}/Dockerfile
git commit -m "Alterações no Dockerfile para a versão ${SERVICE}-${VERSION}"
git tag -a ${SERVICE}-${VERSION} -m "Versão ${SERVICE} ${VERSION}"
git push origin ${SERVICE}-${VERSION}
git push origin master
```

> Builds amd64 rodam **emulados** (qemu) num Mac arm64 — as compilações (PECL, ModSecurity, OpenResty) demoram bastante. Rode o build em background e acompanhe o `build.log`.

---

## 7. Validação (smoke tests) — o que observar

**Nunca confie só no exit code do build** (o `tee` pode mascarar). Sempre confirme no Hub com `imagetools inspect` que **as duas plataformas** (amd64 + arm64) estão presentes, e rode o serviço:

```bash
# PHP: versão + extensões carregadas + wp-cli + usuário www-data (uid 33)
docker run --rm apiki/wphost:php-<v> sh -c 'php -v; php -m; wp --version --allow-root; id'
#   confira: redis, imagick, memcached, apcu, igbinary, ssh2, newrelic, opcache, gd, intl

# nginx: módulos compilados + config válida
docker run --rm apiki/wphost:nginx-<v> sh -c 'nginx -V 2>&1; nginx -t'
#   confira: OpenSSL <esperado>, http_v3, brotli, geoip2, realip

# waf: nginx stable + ModSecurity + CRS + módulo carrega
docker run --rm apiki/wphost:waf-<v> sh -c '
  nginx -v
  ls -la /usr/local/lib/libmodsecurity.so.*
  git -C /coreruleset describe --tags
  echo "load_module /usr/lib/nginx/modules/ngx_http_modsecurity_module.so; events{} http{}" > /tmp/t.conf
  nginx -t -c /tmp/t.conf'
```

---

## 8. ⚠️ Armadilhas conhecidas (aprendidas em produção)

Estas quebram o build; já foram resolvidas mas podem reaparecer em versões futuras:

1. **PHP ≥ 8.5 — OPcache é estático.** A partir do PHP 8.5 o OPcache faz parte do binário e **não pode** ser instalado como extensão compartilhada. **Não inclua `opcache`** em `docker-php-ext-install`, senão o build falha com `cp: can't stat 'modules/*'`. As diretivas `opcache.*` no `.ini` continuam válidas.

2. **`tee` mascara falha do buildx.** Ao usar `docker buildx ... | tee log`, sempre `set -o pipefail` antes; do contrário o exit code do pipe é o do `tee` (0) mesmo com o build falhando. **Sempre** confirme depois com `docker buildx imagetools inspect`.

3. **Debian buster está EOL.** Imagens `debian:buster-slim` falham no `apt-get update` (`does not have a Release file`) porque saíram dos espelhos. Use **`debian:bookworm-slim`**. (O `waf` foi migrado de buster→bookworm em jul/2026.)

4. **Pacotes extintos no bookworm.** Ao migrar de buster: `zlibc` foi **removido** (era redundante, `zlib1g-dev` cobre) e `libpcre++-dev` **não existe** — troque por `libpcre2-dev` (builder) e `libpcre2-8-0` (runtime). Não use **trixie** para o waf: trixie removeu o PCRE1 (`libpcre3-dev`), que o Dockerfile ainda usa.

5. **ModSecurity — submódulos aninhados.** O submódulo `mbedtls` do ModSecurity 3.0.x tem **submódulos próprios**. Clonar com `git submodule init && git submodule update` (não-recursivo) faz o `./configure` falhar com `Mbed TLS was not found within ModSecurity source directory`. Use **`git submodule update --init --recursive`**.

6. **nginx: use a branch _stable_.** No `waf`, `NGINX_VERSION` deve ser da branch estável (1.28.x, 1.30.x — segundo número par), não mainline (1.31.x). O `nginx/all` (OpenResty) segue a versão do OpenResty, que é outra numeração.

7. **git tags históricas incompletas.** Nem todo release antigo tem tag git (ex.: `php-8.4.12`, `php-8.3.x` e `pgbackup-v1` existem no Hub mas não no git). O **Docker Hub é a fonte de verdade** do que está publicado. Criar a tag git faz parte do fluxo ideal daqui pra frente.

---

## 9. Pendências conhecidas (não fechadas)

- **`php/Dockerfile-7`** tem alterações **não commitadas** (conversão para multi-stage, bumps redis 6.1.0 / imagick 3.8.0). Ainda não foi buildado/publicado.
- **`postgre-backup/`** não está rastreada no git, embora a imagem `pgbackup-v1` já esteja no Hub (jan/2026). O código dessa imagem só existe localmente.
- **waf**: avaliar migrar a base para `trixie` no futuro (exigiria substituir PCRE1 por PCRE2 na compilação do nginx).

---

## 10. Referência rápida — estado atual das versões (jul/2026)

| Serviço | Versão | Base |
|---|---|---|
| php 8 | **8.5.8** | `php:8.5.8-fpm-alpine3.24` |
| php 7 | 7.4.33 | `php:7.4.33-fpm-alpine3.16` |
| nginx | **1.31.1.1** | `openresty/openresty:1.31.1.1-2-bookworm-fat` |
| waf | **4.28.0** (CRS) — nginx 1.30.4, ModSecurity 3.0.16 | `debian:bookworm-slim` |
| crowdsec | 0.0.17-rc7 | `debian:stable-slim` |
| postgre-backup | pgbackup-v1 | `alpine:3.19` |
