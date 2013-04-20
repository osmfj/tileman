#!/bin/sh

PREFIX=/opt/tileserver
DESTDIR=${PREFIX}/bin/
CONFDIR=/etc/
OSMOSIS_WORK=/var/opt/osmosis

sudo mkdir -p ${DESTDIR}
sudo mkdir -p ${OSMOSIS_WORK}

sudo install -c osm-updatedb ${DESTDIR}
sudo install -c osm-loaddb ${DESTDIR}
sudo install -c osmdb.conf ${CONFDIR}

sudo cp osmosis_configuration_fablik.txt ${OSMOSIS_WORK}/configuration.txt

echo "Now you should create PostgreSQL/PostGIS database for OSM"
echo "You can use createdb.sh with modification.(mandatory to modify)"
echo "and set DBUSER/DBPASS and DBNAME to /etc/osmdb.conf"
echo "then call /opt/tileserver/bin/osm-loaddb"

