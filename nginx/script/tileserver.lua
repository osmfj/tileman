--
-- Lua script for providing osm tile server
--
--
-- Copyright (C) 2013, Hiroshi Miura
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU Affero General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU Affero General Public License for more details.
--
--    You should have received a copy of the GNU Affero General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

-- required module
local osm_tile = require 'osm.tile'
local tirex = require 'osm.tirex'

local tirex_tilepath = "/var/lib/tirex/tiles/"

local map = ngx.var.map
local x = tonumber(ngx.var.x)
local y = tonumber(ngx.var.y)
local z = tonumber(ngx.var.z)

-- try renderd file.
local png, err = osm_tile.get_tile(map, x, y, z)
if png then
    ngx.header.content_type = 'image/png'
    ngx.print(png)
    return ngx.OK
end

-- ask tirex to render it
local ok = tirex.send_request(map, x, y, z)
if not ok then
   return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local tilefile = osm_tile.xyz_to_metatile_filename(x, y, z)
local tilepath = tirex_tilepath..'/'..map..'/'..tilefile
local png, err = osm_tile.get_tile(tilepath, x, y, z)
if png then
    ngx.header.content_type = 'image/png'
    ngx.print(png)
    return ngx.OK
end
ngx.log(ngx.ERR, err)
return ngx.exit(ngx.HTTP_NOT_FOUND)

-- vi:nosi:sw=4:ts=4
-- EOF --
