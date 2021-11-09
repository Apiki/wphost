map $http_x_forwarded_proto $_scheme {
     default https;
     https https;
     http http;
}


server {
    listen 80;
    listen [::]:80;

    server_name example.com;

    access_log /dev/fd/1;
    error_log /dev/fd/1;

    root /WORDPRESS/www;

    index index.php index.html index.htm;

    include common/php.conf;
    include common/wpcommon.conf;
    include common/locations.conf;
    include /WORDPRESS/www/nginx/*.conf;
}
