--
-- Lua access script for providing osm tile cache
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
local osm_tile = require 'osm.tile'

local minz = tonumber(ngx.var.minz)
local maxz = tonumber(ngx.var.maxz)

local uri = ngx.var.uri
local base = ''
local ext = 'png'

local x, y, z = osm_tile.get_cordination(uri, base, ext)
local ok = osm_tile.check_integrity_xyzm(x, y, z, minz, maxz)
if not ok then
  ngx.exit(ngx.HTTP_FORBIDDEN)
end

-- store x, y, z into nginx var
-- for further check or cache control, tile rendering
ngx.var.x = x
ngx.var.y = y
ngx.var.z = z

