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

-- constants
--
local metatile = 8
local metatile_header_size = 20 + metatile * 64

bit = require 'bit'

-- function: serialize_tirex_msg
-- argument: table msg
--     hash table {key1=val1, key2=val2,....}
-- return: string
--     should be 'key1=val1\nkey2=val2\n....\n'
--
function serialize_tirex_msg (msg)
    local str = ''
    for k,v in pairs(msg) do
        str = str .. k .. '=' .. tostring(v) .. '\n'
    end
    return str
end

-- function: deserialize_tirex_msg
-- arguments: string str: recieved message from tirex
--     should be 'key1=val1\nkey2=val2\n....\n'
-- return: table
--     hash table {key1=val1, key2=val2,....}
function deserialize_tirex_msg (str) 
    local msg = {}
    for line in string.gmatch(str, "[^\n]+") do
        m,_,k,v = string.find(line,"([^=]+)=(.+)")
        if  k ~= '' then
            msg[k]=v
        end
    end
    return msg
end

-- function: xyz_to_filename
-- arguments: int x, y, z
-- return: filename of metatile
-- global: metatile(8) metatile multiplexity
--
function xyz_to_filename (ox, oy, z) 
    local res=''
    local x = tonumber(ox)
    local y = tonumber(oy)
    local v = 0
    -- make sure we have metatile coordinates
    x = x - x % metatile
    y = y - y % metatile

    for i=0, 4 do
        v = bit.band(x, 0x0f)
        v = bit.rshift(v, 4)
        v = bit.bor(v, bit.band(y, 0x0f))
        x = bit.rshift(x, 4)
        y = bit.rshift(y, 4)
        res = res .. tostring(v) .. '/'
    end
    ngx.log(ngx.INFO, res..tostring(z)..'.meta')
    return res .. tostring(z) .. '.meta'
end

-- get long value at offset from buffer
-- FIXME binary operations
function getLong (buffer, offset)
    return ((buffer[offset+3] * 256 + buffer[offset+2]) * 256 + buffer[offset+1]) * 256 + buffer[offset]
end

-- function: send_image
-- arugments: metatile file descriptor fd
--            number x, y, z
-- return:
-- description: send back tile image to client
--
function send_image (fd, x, y, z)
    local header, err = fd:read(metatile_header_size)
    if header == nil then
        fd:close()
        ngx.log(ngx.ERR, "fd read error")
        return ngx.exit(ngx.HTTP_SERVER_INTERNAL_ERROR)
    end

    local pib = 20 + ((y % metatile) * metatile) + ((x % metatile) * metatile*metatile ) -- offset into lookup table in header
    local offset = getLong(header, pib)
    local size = getLong(header, pib+4)
    fd:seek(offset)
    local png = fd:read(size)
    if png == nil then
        fd:close()
        ngx.log(ngx.ERR, "fd:read error")
        return ngx.exit(ngx.HTTP_SERVER_INTERNAL_ERROR)
    end

    ngx.header.content_type = 'image/png'
    ngx.print(png)
    fd:close()
    return
end

-- function: get_imgfile
-- arguments: string map
--            number x, y, z
-- return string filename
--
function get_imgfile (map, x, y, z)
    ngx.log(ngx.INFO, "xyz", x, y, z)
    local imgfile = "/var/lib/tirex/tiles/"
    if map == nil or map == "" then
        imgfile = imgfile..xyz_to_filename(x, y, z)
    else
        imgfile = imgfile..map.."/"..xyz_to_filename(x, y, z)
    end
    return imgfile
end

-- funtion: send_tile_tilrex
-- argument: filedescriptor udp
--           string map
--           number x, y, z
-- return:  void
--
-- it send back tile to client
--
function send_tile_tirex (map, x, y, z, id)
    local udpsock = ngx.socket.udp()
    udpsock:settimeout(1000)
    local ok, err = udpsock:setpeername('unix:/var/run/tirex/master.sock')
    if not ok then
        ngx.log(ngx.ERR, "udpsock setpeername error")
        return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end

    local mx = x - x % metatile
    local my = y - y % metatile
    local priority = 8
    local req = serialize_tirex_msg({
        ["id"]   = 'luats-'..tostring(id));
        ["type"] = 'metatile_enqueue_request';
        ["prio"] = priority;
        ["map"]  = map;
        ["x"]    = mx;
        ["y"]    = my;
        ["z"]    = z})

    local ok, err = udpsock:send(req)
    if not ok then
        ngx.log(ngx.ERR, "udp send error")
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    local data, err = udpsock:receive()
    if not data then
        ngx.log(ngx.ERR, "failed to read a packet: ", data)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    udpsock:close()

    local msg = deserialize_tirex_msg(tostring(data))
    if msg["id"]:sub(1,5) ~= "luats" then
        return
    end

    local imgfile = get_imgfile(map, x, y, z)
    local fd, err = io.open(imgfile,"rb")
    if fd == nil then
        fd:close()
        ngx.log(ngx.ERR, "io open error")
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    else
        ngx.shared.stats.incr("tiles_rendered", 1)
        send_image(fd, map, x, y, z)
        fd:close()
    end
end

-- main routine
--
--
ngx.shared.stats:incr("http_requests", 1)
local id = ngx.shared.stats:incr("tiles_requested", 1)
if id == nil then
    ngx.log(ngx.ERR, "stat dict error")
    id = 0
end

local map = 'example'
local x = ngx.var.x
local y = ngx.var.y
local z = ngx.var.z

local imgfile = get_imgfile(map, x, y, z)
local fd, err = io.open(imgfile,"rb")
if fd == nil then
    send_tile_tirex(map, x, y, z, id)
else
    ngx.shared.stats:incr("tiles_from_cache", 1)
    send_image(fd, map, x, y, z)
    fd:close()
end

-- vi:nosi:sw=4:ts=4
-- EOF --
