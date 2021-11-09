#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

if [ -z "$(ls -A ${MAIN_DIR}/www)" ]; then
	echo "** Starting WordPress setup **"

	mkdir ${MAIN_DIR}/www/

	set -ex; \
	cd /tmp; \
	curl -o /tmp/wordpress.tar.gz -fSL "https://br.wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
	echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
	# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf /tmp/wordpress.tar.gz -C /tmp; \
	rm /tmp/wordpress.tar.gz; \
	cp -rf /tmp/wordpress/* ${MAIN_DIR}/www/ && \
	chown -R www-data:www-data ${MAIN_DIR}/www; \
	rm -rf /tmp/wordpress/

	echo "** WordPress setup finished! **"
fi

if [ -z "$(ls -A ${MAIN_DIR}/openresty)" ]; then
	echo "** Deploying Nginx build **"
	cp -rf ${STRUCTURE_OPTS}/openresty ${MAIN_DIR}/
	echo "** Nginx build finished! **"
fi

if [ -z "$(ls -A ${MAIN_DIR}/infrastructure-design)" ]; then
	echo "** Deploying infrastructure-design **"
	cp -rf ${STRUCTURE_OPTS} ${MAIN_DIR}/
	echo "** infrastructure-design finished! **"
fi

[ -f /usr/local/etc/php-fpm.d/www.conf ] && [ ! -L /usr/local/etc/php-fpm.d/www.conf ] && {
	rm /usr/local/etc/php-fpm.d/www.conf
	ln -s ${MAIN_DIR}/infrastructure-design/misc/www-data.conf /usr/local/etc/php-fpm.d/www.conf
}

[ ! -L /usr/local/etc/php/conf.d/php-apiki.ini ] && {
	ln -s ${MAIN_DIR}/infrastructure-design/misc/php-apiki.ini /usr/local/etc/php/conf.d/php-apiki.ini
}

[ ! -L /etc/msmtprc ] && {
	ln -s ${MAIN_DIR}/infrastructure-design/misc/msmtprc /etc/msmtprc
}

echo ""
exec "$@"