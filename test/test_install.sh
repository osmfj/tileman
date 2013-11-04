#!/bin/sh

PREFIX   ?= /opt/tileman
DESTDIR  ?= ${PREFIX}/bin/
HTMLDIR  ?= ${PREFIX}/html/
CACHEDIR ?= ${PREFIX}/cache/
STATICDIR?= ${PREFIX}/tiles/
CONFDIR  ?= ${PREFIX}/etc/
NGINX    ?= ${CONFDIR}/nginx
WORKDIR  ?= ${PREFIX}/osmosis
HTMLDIR  ?= ${PREFIX}/www
SRCROOT  ?= `pwd`

cp ${SRCROOT}/osmosis/fabrik.txt $(WORKDIR)/configuration.txt
mkdir -p ${HTMLDIR}
cp ${SRCROOT}/test/example.html ${HTMLDIR}/index.html
cp ${SRCROOT}/test/tirex_mapnik_custom.conf ${CONFDIR}/tirex/renderer/mapnik/custom.conf
cp ${SRCROOT}/test/tileman-test ${CONFDIR}/nginx/sites-enabled/tileman-test
/usr/bin/python ${SRCROOT}/test/mapnik_stylesheets_generate_xml.py /etc/mapnik-osm-data/osm.xml /etc/mapnik-osm-data/custom.xml --password '' --dbname gis --host 'localhost' --user osm --port 5432

