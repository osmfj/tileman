#!/usr/bin/env bash

# Test preparation script
TESTDIR=test
DBUSER=postgres

# setup postgis database
sudo -u ${DBUSER} /usr/bin/tileman-create

# default test data is taiwan (about 16MB by .pbf)
echo  COUNTRY=taiwan >> /etc/tileman.conf
echo  MEMSIZE=1024 >> /etc/tileman.conf
echo  PROCESS_NUM=1　>> /etc/tileman.conf
echo  WORKDIR_OSM=/var/lib/osmosis >> /etc/tileman.conf
echo  OSMOSIS_BIN=/usr/bin/osmosis >> /etc/tileman.conf

cp -p ${TESTDIR}/taiwan-latest.osm.pbf /tmp
cp -p ${TESTDIR}/state.txt /tmp
(cd /tmp;sudo -u ${DBUSER} /usr/bin/tileman-load -p )
