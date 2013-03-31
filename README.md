Tile Cache recipe for tile.openstreetmap.jp
=========

Here is a repository to maintain tile.openstreetmap.jp tile cache/tile server.
It uses following technologies.

- Nginx Web server

  - Lua embeded scripting 

  - File Cache

- Redis Key-Value store database

 - Lua resty redis driver

- Tirex, rendering backend

- PostGIS

- osm2pgsql

- osmosis

This recipe is intended to run on Ubuntu 11.10(x86_64) server but it may be
useful for other platform and who want to run osm tile server.


License
-- 

The recipe is distributed under AGPLv3
Each softwares are  under each licenses.

Maintainer
--

It is maintained by OpenStreetMap Foundation Japan.


Design
==

Nginx serves tile proxy. It returns disk cache and escalate to upstream
tile.openstreetmap.org servers when needed.
Lua script included by Nginx controls local rendering.
It is an asumption that postgis server has limited osm data in region.

Lua script retrive x/y/z parameter and check an existence of 
tile data. If it is other area where the server provided, it goes upstream.
It also check freshness of tile data. If data has been updated by importing,
it ask renderd to generate new tile.

In order to manage these meta-data, we use Redis KVS DBMS.
Redis holds 3 type of data.

- "a:x:y:z" avalability of data and its freshness. If key is exist, the server
 can provide tile for its x/y/z. If value is "d", it means tile should be regenerate.
- "r:x:y:z" latest tile request date/time. It is updated by Lua script.
- "c:x:y:z" access counter for specific tile. It can be used to analyzes 
 statistics.

We need another script to maintain tile generation control.
We can get expire.list as "Tile expire method" explaines when importing diff.osm.
http://wiki.openstreetmap.org/wiki/Tile_expire_methods

We need to process it and update Redis KVS db expressed for tile expiry.

planet import
---

The directory updatedb has an incremental update script for osm data.

Reference
--


- http://svn.openstreetmap.org/applications/utils/tirex/tileserver/tileserver.js

- http://wiki.openstreetmap.org/wiki/User:Stephankn/knowledgebase#Cleanup_of_ways_outside_the_bounding_box

Sever environment
==

* Mapnik2.2

you can get mapnik 2.2.0 from 

- https://launchpad.net/~mapnik/+archive/nightly-trunk/+packages

You can build most recent mapnik

- https://github.com/mapnik/mapnik-packaging/tree/master/debian-nightlies


* Tirex

Please follow an instraction  here:

- http://wiki.openstreetmap.org/wiki/Tirex/Building_and_Installing

To-dos
--

- import tool
- A part to ask renderd to generate tile
- server setup for PostGIS/renderd


 
 
 

