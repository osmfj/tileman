#!/bin/bash

PREFIX=${PREFIX:-/opt/tileman}
DESTDIR=${DESTDIR:-${PREFIX}/bin/}
SHAREDIR=${SHAREDIR:-/opt/tileman/share}
VARDIR=${VARDIR:-/opt/tileman/var}
HTMLDIR=${HTMLDIR:-${SHAREDIR}/html/}
CACHEDIR=${CACHEDIR:-${VARDIR}/cache/}
STATICDIR=${STATICDIR:-${VARDIR}/tiles/}
CONFDIR=${CONFDIR:-${PREFIX}/etc/}
NGINX=${NGINX:-${CONFDIR}/nginx}
WORKDIR=${WORKDIR:-${VARDIR}/osmosis}
SRCROOT=${SRCROOT:-`pwd`}

cp ${SRCROOT}/osmosis/fabrik.txt ${WORKDIR}/configuration.txt
mkdir -p ${HTMLDIR}
cp ${SRCROOT}/test/example.html ${HTMLDIR}/index.html
cp ${SRCROOT}/test/tirex_mapnik_custom.conf ${CONFDIR}/tirex/renderer/mapnik/custom.conf
cp ${SRCROOT}/test/tileman-test ${CONFDIR}/nginx/sites-enabled/tileman-test
/usr/bin/python ${SRCROOT}/test/mapnik_stylesheets_generate_xml.py /etc/mapnik-osm-data/osm.xml /etc/mapnik-osm-data/custom.xml --dbname gis --user postgres
