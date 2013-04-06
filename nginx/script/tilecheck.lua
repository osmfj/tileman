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
local minz = 0
local maxz = 18

if ngx.var.uri:sub(-4) ~= ".png" then
  ngx.exit(ngx.HTTP_FORBIDDEN)
end

local captures = "/(%d+)/(%d+)/(%d+).png"
local s,_,z,x,y = ngx.var.uri:find(captures)
if s == nil then
  ngx.exit(ngx.HTTP_NOT_FOUND)
end

if (tonumber(z) < minz) or (tonumber(z) > maxz) then
  ngx.exit(ngx.HTTP_FORBIDDEN)
end

