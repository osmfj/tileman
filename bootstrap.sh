#!/usr/bin/env bash
#
# bootstrap script for vagrant env
#
ROOTDIR=${ROOTDIR:=/vagrant}

useradd osm

export DEBIAN_FRONTEND=noninteractive

# use Apt-cacher on host
#
# if you use apt-cacher on host to reduce downloding time,
# please remove comment out -- recoomend.

#echo 'Acquire::http::Proxy "http://192.168.123.1:3142";' >> /etc/apt/apt.conf.d/01tileman

# don't install recommend packages to reduce size
#echo 'APT::Install-Recommends "0"; \
#      APT::Install-Suggests "0";' >> /etc/apt/apt-conf.d/01tileman

apt-get update -qq

# add osmjapan PPA repository
apt-get install -qq python-software-properties
apt-add-repository -y ppa:osmjapan/ppa
apt-add-repository -y ppa:lwarx/postgis-pg93-bp

# testing packages
#apt-add-repository -y ppa:osmjapan/testing

# development packages
#apt-add-repository -y ppa:miurahr/openstreetmap

apt-get update -qq

# install nginx/openresty
apt-get install -qq nginx-openresty
#apt-get install -y nginx-extras # > 1.4.1-0ppa1


# install mapnik
apt-get install -qq libmapnik-dev
apt-get install -qq ttf-unifont ttf-dejavu ttf-dejavu-core ttf-dejavu-extra

# default locale will be taken from user locale so we set locale to UTF8
sudo update-locale LANG=en_US.UTF-8
export LANG=en_US.UTF-8
# install postgis
apt-get install -qq postgresql-9.1 postgresql-contrib-9.1 postgresql-9.1-postgis-2.1
# install osm2pgsql
apt-get install --no-install-recommends -qq osm2pgsql
#apt-get install -y --force-yes -o openstreetmap-postgis-db-setup::initdb=gis -o openstreetmap-postgis-db-setup::dbname=gis -o openstreetmap-postgis-db-setup::grant_user=osm openstreetmap-postgis-db-setup osm2pgsql

# install Tirex
apt-get install -qq tirex-core tirex-backend-mapnik tirex-example-map

# install Lua OSM library
apt-get install -qq geoip-database lua5.1 lua-bitop

# install osmosis
apt-get install -qq openjdk-7-jre
${ROOTDIR}/osmosis/osmosis-installer.sh

# development dependencies
apt-get install -qq devscripts debhelper dh-autoreconf build-essential git
apt-get install -qq libfreexl-dev libgdal-dev python-gdal gdal-bin
apt-get install -qq libxml2-dev python-libxml2 libsvg

apt-get install -qq libjs-leaflet
apt-get install -qq openstreetmap-mapnik-stylesheet-data

# install tileman / lua-nginx-osm

## if you want to test library
## use follows instead of ppa package.
# (cd /vagrant/; \
#  git submodule init; \
#  git submodule update; \
#  cd lua-nginx-osm; \
#  debuild -us -uc -b -i; \
#  cd .. ; dpkg -i lua-nginx-osm*.deb)
##
apt-get install -qq lua-nginx-osm

# install tileman
apt-get install -qq tileman

# install from source
#(cd ${ROOTDIR}; \
# make  PREFIX=/usr HTMLDIR=/var/www CONFDIR=/etc CACHEDIR=/var/cache/tileman STATICDIR=/var/lib/tileman/tiles WORKDIR=/var/lib/osmosis install
