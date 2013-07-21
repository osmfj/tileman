#!/usr/bin/env bash

apt-get update

# add osmjapan PPA repository
apt-get install -y python-software-properties
apt-add-repository -y ppa:osmjapan/ppa
apt-get update

# install nginx
apt-get install -y nginx-extras

# install mapnik
apt-get install -y libmapnik-dev
apt-get install -y ttf-unifont ttf-dejavu ttf-dejavu-core ttf-dejavu-extra

# install postgis
apt-get install -y postgresql-9.1 postgresql-contrib-9.1 postgresql-9.1-postgis

# install Tirex
apt-get install -y tirex-core tirex-backend-mapnik tirex-example-map

# install Lua OSM library
apt-get install -y geoip-database lua5.1 lua-bitop
apt-get install -y lua-nginx-osm

# install osm2pgsql
apt-get install -y osm2pgsql

# install osmosis
apt-get install -y openjdk-7-jre
cd /vagrant
wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz
mkdir -p /opt/osmosis
cd /opt/osmosis;tar zxf /vagrant/osmosis-latest.tgz
mkdir -p /var/opt/osmosis
chown vagrant /var/opt/osmosis

# install tileman package
apt-get install -y tileman

# development dependencies
apt-get install -y devscripts debhelper dh-autoreconf build-essential git
apt-get install -y libfreexl-dev libgdal-dev python-gdal gdal-bin
apt-get install -y libxml2-dev python-libxml2 libsvg

# install Redis-server
apt-get install -y redis-server
apt-get install -y lua-nginx-redis

# setup postgis database
su postgres /usr/bin/tileman-create

# clone tileman source
#cd /vagrant
#git clone git://github.com/osmfj/tileman.git
#git submodule init
#git submodule update

