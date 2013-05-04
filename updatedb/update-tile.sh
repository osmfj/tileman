#!/bin/sh

MAPNAME=custom
CONCURRENCY=2

EXPIRE_LIST_PIPE=/var/opt/tileserver/expire.list
EXPIRE_LIST_FILE=/var/opt/osmosis/expire.list

RENDER_EXPIRED_BIN=/opt/tileserver/bin/render_expired
TILEDIR=/var/lib/tirex/tiles

MODTILE_SOCK=/var/lib/tirex/modtile.sock

cat ${EXPIRE_LIST_FILE} | ${RENDER_EXPIRED_BIN} -t ${TILEDIR} -m ${MAPNAME} -s ${MODTILE_SOCK} -n ${CONCURRENCY}
