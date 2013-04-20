#!/bin/sh

echo "Do you run it on postgres user?[N/y]"
read ans
if [ "$ans" = "" -o "$ans" = "n" -o "$ans" = "N" ] ; then
  exit 1
fi

# sudo -u postgres -i -H
createuser -SdR osm
createdb -E UTF8 -O osm gis
createlang plpgsql gis
psql -d gis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
psql -d gis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql

psql gis -c "ALTER TABLE geometry_columns OWNER TO osm"
psql gis -c "ALTER TABLE spatial_ref_sys OWNER TO osm"

