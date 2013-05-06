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

local region = {
    {x1=153.890100, y1=26.382110, x2=131.691500, y2=21.209920},
    {x1=131.691500, y1=21.209920, x2=122.595400, y2=23.519660},
    {x1=122.595400, y1=23.519660, x2=122.560700, y2=25.841460},
    {x1=122.560700, y1=25.841460, x2=128.814500, y2=34.748350},
    {x1=128.814500, y1=34.748350, x2=129.396600, y2=35.094030},
    {x1=129.396600, y1=35.094030, x2=140.576900, y2=45.706480},
    {x1=140.576900, y1=45.706480, x2=149.189100, y2=45.802450},
    {x1=149.189100, y1=45.802450, x2=153.890100, y2=26.382110}
   }
   
local region2 = { -- cannot check because it is too complex
    {x1=153.890100, y1=26.382110, x2=132.152900, y2=26.468090},
    {x1=132.152900, y1=26.468090, x2=131.691500, y2=21.209920},
    {x1=131.691500, y1=21.209920, x2=122.595400, y2=23.519660},
    {x1=122.595400, y1=23.519660, x2=122.560700, y2=25.841460},
    {x1=122.560700, y1=25.841460, x2=128.814500, y2=34.748350},
    {x1=128.814500, y1=34.748350, x2=129.396600, y2=35.094030},
    {x1=129.396600, y1=35.094030, x2=135.307900, y2=37.547400},
    {x1=135.307900, y1=37.547400, x2=140.576900, y2=45.706480},
    {x1=140.576900, y1=45.706480, x2=149.189100, y2=45.802450},
    {x1=149.189100, y1=45.802450, x2=153.890100, y2=26.382110}
   }

function check_region(region, x, y, z)
    local target = true
    local n = 2 ^ z
    local lon_deg = x / n * 360.0 - 180.0
    local lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * y / n)))
    local lat_deg = lat_rad * 180.0 / math.pi
    for k, v in pairs(region) do
        local result = (v.y1 - v.y2) * lon_deg + (v.x2 - v.x1) * lat_deg+ v.x1 * v.y2 - v.x2 * v.y1
        if result > 0 then
            target = nil
        end
    end
    return target
end

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

local inside = check_region(region, x, y, z)

if ngx.var.own_tile == "no" then
  if not inside then
      return ngx.exit(ngx.HTTP_SEE_OTHER)
  else
      return ngx.exit(ngx.HTTP_NOT_ALLOWED)
  end
end
