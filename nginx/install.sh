#!/bin/sh
NGINX=/etc/nginx

install tileproxy_params $NGINX/
install conf.d/* $NGINX/conf.d/
mkdir -p $NGINX/script/
install script/* $NGINX/script/
install sites/* $NGINX/sites-available/

# example to enable configuration on ubuntu/debian
#ln -s $NGINX/sites-available/tileproxy $NGINX/sites-enabled/tileproxy
#ln -s $NGINX/sites-available/tileproxy_ssl $NGINX/sites-enabled/tileproxy_ssl
