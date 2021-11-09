#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

/usr/bin/nginx -g "daemon off;" &
php-fpm --nodaemonize;
exec while true; do sleep 1d; done