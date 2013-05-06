--
-- Lua access script for providing osm tile cache
--
-- requisite: lua-resty-redis, socket
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
local bit = require 'bit'

-- FIXME: need to check integlity and existence of external parameters
-- minz, maxz, allow_jpg, url_rule
--
local minz = tonumber(ngx.var.minz)
local maxz = tonumber(ngx.var.maxz)

-- only support png tiles
if ngx.var.uri:sub(-4) ~= ".png" then
  -- if allow_jpg == true then
  -- pass
  -- else
  ngx.exit(ngx.HTTP_FORBIDDEN)
end

-- FIXME: captures should be generated from url_rule and
-- need to check its integlity.
-- it may be two pattern.
--   1) /z/x/y.{png|jpg}
--   2) /mapn/z/x/y.png
--
local captures = "/(%d+)/(%d+)/(%d+).png"
local s,_,oz,ox,oy = ngx.var.uri:find(captures)
if s == nil then
  ngx.exit(ngx.HTTP_NOT_FOUND)
end

local x = tonumber(ox)
local y = tonumber(oy)
local z = tonumber(oz)

-- check x,y,z limitation
--
if z < minz or z > maxz then
  ngx.exit(ngx.HTTP_FORBIDDEN)
end

local lim = 0
lim = bit.lshift(1, z)
if x<0 or x>=lim or y<0 or y>=lim then
  ngx.exit(ngx.HTTP_FORBIDDEN)
end

-- store x, y, z into nginx var
-- for further check or cache control, tile rendering
ngx.var.x = ox
ngx.var.y = oy
ngx.var.z = oz

if ngx.var.own_tile == "no" then
  ngx.location.capture("/tileserver")
end
