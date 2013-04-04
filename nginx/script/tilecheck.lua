--
-- Lua access script for providing osm tile cache
--
-- requisite: lua-resty-redis, socket
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

