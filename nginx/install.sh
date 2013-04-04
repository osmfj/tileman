#!/bin/sh
NGINX=/etc/nginx

install tileproxy_params $NGINX/
install conf.d/* $NGINX/conf.d/
mkdir -p $NGINX/script/
install script/* $NGINX/script/
install sites/* $NGINX/sites-available/

ln -s $NGINX/site-available/tileproxy $NGINX/site-enabled/tileproxy
ln -s $NGINX/site-available/tileproxy_ssl $NGINX/site-enabled/tileproxy_ssl
