#!/usr/bin/env bash

ROOTDIR=/vagrant

useradd osm

export DEBIAN_FRONTEND=noninteractive

# use Apt-cacher on host
#
# if you use apt-cacher on host to reduce downloding time,
# please remove comment out -- recoomend.

#echo 'Acquire::http::Proxy "http://192.168.123.1:3142";' >> /etc/apt/apt.conf.d/01tileman

# don't install recommend packages to reduce size
echo 'APT::Install-Recommends "0"; \
      APT::Install-Suggests "0";' >> /etc/apt/apt-conf.d/01tileman

apt-get update

# add osmjapan PPA repository
apt-get install -y python-software-properties
apt-add-repository -y ppa:osmjapan/ppa
#apt-add-repository -y ppa:osmjapan/testing
apt-add-repository -y ppa:miurahr/openstreetmap
apt-get update

# install nginx/openresty
apt-get install -y nginx-openresty
#apt-get install -y nginx-extras # > 1.4.1-0ppa1


# install mapnik
apt-get install -y libmapnik-dev
apt-get install -y ttf-unifont ttf-dejavu ttf-dejavu-core ttf-dejavu-extra

# default locale will be taken from user locale so we set locale to UTF8
sudo update-locale LANG=en_US.UTF-8
export LANG=en_US.UTF-8
# install postgis
apt-get install -y postgresql-9.1 postgresql-contrib-9.1 postgresql-9.1-postgis
# install osm2pgsql
apt-get install -y --force-yes -o openstreetmap-postgis-db-setup::initdb=gis -o openstreetmap-postgis-db-setup::dbname=gis -o openstreetmap-postgis-db-setup::grant_user=osm openstreetmap-postgis-db-setup osm2pgsql

# install Tirex
apt-get install -y tirex-core tirex-backend-mapnik tirex-example-map

# install Lua OSM library
apt-get install -y geoip-database lua5.1 lua-bitop

# install osmosis
apt-get install -y openjdk-7-jre
cd /tmp
if [ -f osmosis-latest.tgz ]; then
wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz
fi
mkdir -p /opt/osmosis
cd /opt/osmosis;tar zxf /tmp/osmosis-latest.tgz
mkdir -p /var/opt/osmosis
chown osm /var/opt/osmosis


# development dependencies
apt-get install -y devscripts debhelper dh-autoreconf build-essential git
apt-get install -y libfreexl-dev libgdal-dev python-gdal gdal-bin
apt-get install -y libxml2-dev python-libxml2 libsvg

apt-get install -y libjs-leaflet
apt-get install -y openstreetmap-mapnik-stylesheet-data

# install tileman package
apt-get install -y lua-nginx-osm tileman
cd /vagrant/lua-nginx-osm
debulid -us -uc -b -i
cd ..
dpkg -i lua-nginx-osm*.deb
#debuild -us -uc -b -i
#dpkg -i tileman*.deb

# update tileman-* utils
install ${ROOTDIR}/bin/tileman-* /usr/bin/

${ROOTDIR}/test/load.sh
