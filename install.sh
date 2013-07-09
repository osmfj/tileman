#!/bin/bash

DISTRO=debian #ubuntu/debian
#DISTRO=redhat #redhat/centos/fedora

PREFIX=/opt/tileman
DESTDIR=${PREFIX}/bin/
HTMLDIR=${PREFIX}/html/
CACHEDIR=${PREFIX}/cache/
STATICDIR=$PREFIX/tiles/

CONFDIR=/etc/
NGINX=${CONFDIR}/nginx

OSMOSIS_WORK=/var/opt/osmosis

mkdir -p ${DESTDIR}
mkdir -p ${OSMOSIS_WORK}
mkdir -p ${HTMLDIR}

echo "make ${CACHEDIR} directory for tile cache"
mkdir -p ${CACHEDIR}
chmod 777 ${CACHEDIR}

echo "Locating example static tile on ${STATICDIR}..."
mkdir -p ${STATICDIR}
bzcat data/Liancourt_Rocks_lang_ja_tiles.tar.bz2 |(cd ${STATICDIR};tar xf -)

echo "Install nginx configurations..."
install nginx/tileproxy_params $NGINX/
install nginx/common_location_params $NGINX/
install nginx/ssl_params $NGINX/

if [ "${DISTRO}" = "debian" ]; then
  install nginx/conf.d/* $NGINX/conf.d/
  install nginx/sites/* $NGINX/sites-available/
  # example to enable configuration on ubuntu/debian
  echo "You can now enable server configurations as follows:"
  echo "ln -s $NGINX/sites-available/tileproxy $NGINX/sites-enabled/tileproxy"
  echo "ln -s $NGINX/sites-available/tileproxy_ssl $NGINX/sites-enabled/tileproxy_ssl"
else
  install nginx/conf.d/lua.conf $NGINX/conf.d/_lua.conf
  install nginx/conf.d/geoip.conf $NGINX/conf.d/_geoip.conf
  install nginx/conf.d/tilecache.conf $NGINX/conf.d/_tilecache.conf
  #
  install nginx/sites/tileproxy $NGINX/conf.d/tileproxy.conf.ex
  install nginx/sites/tileproxy_ssl $NGINX/conf.d/tileproxy_ssl.conf.ex
  install nginx/sites/tileserver $NGINX/conf.d/tileserver.conf.ex
  install nginx/sites/tileserver_ssl $NGINX/conf.d/tileserver_ssl.conf.ex
  echo "Please see $NGINX/conf.d/*.conf.ex for configuration examples."
fi

# install updatedb utils
echo "Install osm/postgis utilities..."
install -c bin/* ${DESTDIR}
install -c etc/*.conf ${CONFDIR}

cp updatedb/osmosis_conf/fabrik.txt ${OSMOSIS_WORK}/configuration.txt

echo "Now you should create PostgreSQL/PostGIS database for OSM"
echo "After you set DBUSER/DBPASS and DBNAME to /etc/tileman.conf"
echo "You can use /opt/tileman/bin/tileman-create"
echo "and /opt/tileman/bin/tileman-load"

