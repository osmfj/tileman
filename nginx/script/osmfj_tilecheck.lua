--
-- Lua access script for providing osm tile cache
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
local bit = require 'bit'

local japan = { -- need split to multiple convex polygon
   {
    {lon=153.890100, lat=26.382110},
    {lon=135.307900, lat=37.547400},
    {lon=140.576900, lat=45.706480},
    {lon=149.189100, lat=45.802450},
    {lon=153.890100, lat=26.382110}
   },
   {
    {lon=132.152900, lat=26.468090},
    {lon=131.691500, lat=21.209920},
    {lon=122.595400, lat=23.519660},
    {lon=122.560700, lat=25.841460},
    {lon=128.814500, lat=34.748350},
    {lon=129.396600, lat=35.094030},
    {lon=132.152900, lat=26.468090}
   },
   {
    {lon=153.890100, lat=26.382110},
    {lon=132.152900, lat=26.468090},
    {lon=129.396600, lat=35.094030},
    {lon=135.307900, lat=37.547400},
    {lon=153.890100, lat=26.382110}
   }
}

-- tile to lon/lat
function num2deg(x, y, zoom)
    local n = 2 ^ zoom
    local lon_deg = x / n * 360.0 - 180.0
    local lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * y / n)))
    local lat_deg = math.deg(lat_rad)
    return lon_deg, lat_deg
end

-- lon/lat to tile
function deg2num(lon, lat, zoom)
    local n = 2 ^ zoom
    local lon_deg = tonumber(lon)
    local lat_rad = math.rad(lat)
    local xtile = math.floor(n * ((lon_deg + 180) / 360))
    local ytile = math.floor(n * (1 - (math.log(math.tan(lat_rad) + (1 / math.cos(lat_rad))) / math.pi)) / 2)
    return xtile, ytile
end

-- tile cordinate scale to zoom
function zoom_num(x, y, z, zoom)
    if z > zoom then
        local nx = bit.rshift(x, z-zoom)
        local ny = bit.rshift(y, z-zoom)
        return nx, ny
    elseif z < zoom then
        local nx = bit.lshift(x, zoom-z)
        local ny = bit.lshift(y, zoom-z)
        return nx, ny
    end
    return x, y
end

function check_region(region, x, y, z)
    -- check inclusion of polygon
    local nx, ny = zoom_num(x, y, z, 20)
    local includes = nil
    for _, b in pairs(region) do
        local x1=nil
        local y1 = nil
        local tmp_inc = true
        for _, v in pairs(b) do
            local x2, y2 = deg2num(v.lon, v.lat, 20)
            if x1 ~= nil then
                local res = (y1 - y2) * nx + (x2 - x1) * ny + x1 * y2 - x2 * y1
                if res < 0 then
                    tmp_inc = nil
                end
            end
            x1=x2
            y1=y2
        end
        if tmp_inc == true then
            includes = true
        end
    end
    return includes
end



-- FIXME: need to check integlity and existence of external parameters
-- minz, maxz, allow_jpg, url_rule
--
local minz = tonumber(ngx.var.minz)
local maxz = tonumber(ngx.var.maxz)
local proxyz = tonumber(ngx.var.proxyz)

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

if z < proxyz then -- low zoom use global site cache
    ngx.exec("@tilecache")
end

local inside = check_region(japan, x, y, z)
if not inside then
    ngx.exec("@tilecache")
end
