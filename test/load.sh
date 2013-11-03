#!/usr/bin/env bash

# Test preparation script
ROOTDIR=/vagrant

# setup postgis database
su postgres -c /usr/bin/tileman-create

# default test data is taiwan (about 16MB by .pbf)
echo  COUNTRY=taiwan >> /etc/tileman.conf
echo  MEMSIZE=1024 >> /etc/tileman.conf
echo  PROCESS_NUM=1　>> /etc/tileman.conf

cp -p ${ROOTDIR}/test/taiwan-latest.osm.pbf /tmp
cp -p ${ROOTDIR}/test/state.txt /tmp
(cd /tmp;su osm -c /usr/bin/tileman-load)

# test setup
#
mkdir -p /var/www
cp ${ROOTDIR}/test/example.html /var/www/index.html
cp ${ROOTDIR}/test/tirex_mapnik_custom.conf /etc/tirex/renderer/mapnik/custom.conf
cp ${ROOTDIR}/nginx/sites/tileman-server /etc/nginx/sites-enabled/default
echo '127.0.2.1 tileserver' >> /etc/hosts
/usr/bin/python ${ROOTDIR}/bin/mapnik_stylesheets_generate_xml.py /etc/mapnik-osm-data/osm.xml /etc/mapnik-osm-data/custom.xml --password '' --dbname gis --host 'localhost' --user osm --port 5432 

# start servers
service tirex-backend-manager start
service tirex-master
service nginx start

