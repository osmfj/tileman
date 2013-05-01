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
local bit = require 'bit'

-- constants
--
local metatile = 8

-- vals from nginx conf
--
local map = ngx.var.map
local x = ngx.var.x
local y = ngx.var.y
local z = ngx.var.z

-- shared dictionary
--
local stats = ngx.shared.stats

-- ---------------------------------------------------------------
-- Tirex Interface
--
-- ---------------------------------------------------------------
local tirexsock = 'unix:/var/run/tirex/master.sock'
local tirextile = "/var/lib/tirex/tiles/"
local tirex_shmem_timeout = 120000

-- shared dictionary
--
local tirex = ngx.shared.tirex

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

-- function: register_result
--
--
function register_result(map, mx, my, z)
    local index = string.format("%s:%d:%d:%d",map, mx, my, z)
    tirex:add(index, 0, tirex_shmem_timeout, 0)
    tirex:incr(index, 1)
end

-- function: wait_result
--
--
function wait_result(map, x, y, z)
    --- XXX metatile = 8
    local mx = x - x % 8
    local my = y - y % 8
    local index = string.format("%s:%d:%d:%d",map, mx, my, z)
    for i=0, 6 do -- wait 5*6 = 30sec
        local val, flag = tirex:get(index)
        if val then
            return send_imgfile(map, x, y, z)
        end
        ngx.sleep(5)
    end
    return nil
end

-- funtion: send_tile_tilrex
-- argument: filedescriptor udp
--           string map
--           number x, y, z
-- return:  void
--
-- it send back tile to client
--
function send_tile_tirex (map, x, y, z, priority, id)
    local udpsock = ngx.socket.udp()
    local socketpath = tirexsock
    udpsock:settimeout(10000) -- FIXME

    local ok, err = udpsock:setpeername(socketpath)
    if not ok then
        ngx.log(ngx.ERR, "udpsock setpeername error")
        return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end

    local mx = x - x % 8 -- metatile:8
    local my = y - y % 8
    local req = serialize_tirex_msg({
        ["id"]   = tostring(id);
        ["type"] = 'metatile_enqueue_request';
        ["prio"] = priority;
        ["map"]  = map;
        ["x"]    = mx;
        ["y"]    = my;
        ["z"]    = z})

    local ok, err = udpsock:send(req)
    if not ok then
        ngx.log(ngx.ERR, "tirex: Command send error")
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    local data, err = udpsock:receive()
    udpsock:close()
    if not data then
        -- wait result 30sec
        return wait_result(map, x, y, z)
    end

    local msg = deserialize_tirex_msg(tostring(data))
    if msg["result"] ~= "ok" then
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    register_result(map, msg["x"],msg["y"],msg["z"])
    stats:incr("tiles_rendered", 1)

    if tostring(msg["id"]) == tostring(id) then
        return send_imgfile(map, x, y, z)
    else
        -- wait result 30sec
        return wait_result(map, x, y, z)
    end
end

-- ---------------------------------------------------------------
-- Metatile routines
--
-- ---------------------------------------------------------------

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
    -- XXX
    local mx = x - x % 8
    local my = y - y % 8

    for i=0, 4 do
        v = bit.band(mx, 0x0f)
        v = bit.lshift(v, 4)
        v = bit.bor(v, bit.band(my, 0x0f))
        mx = bit.rshift(mx, 4)
        my = bit.rshift(my, 4)
        res = '/'..tostring(v)..res
    end
    return tostring(z)..res..'.meta'
end

-- get offset value from buffer
-- buffer should be string
-- offset is from 0-
-- s:byte(o) is counting from 1-
function get_offset (buffer, offset)
    return ((buffer:byte(offset+4) * 256 + buffer:byte(offset+3)) * 256 + buffer:byte(offset+2)) * 256 + buffer:byte(offset+1)
end

-- function: send_image
-- arugments: metatile file descriptor fd
--            number x, y, z
-- return:
-- description: send back tile image to client
--
function send_image (fd, sx, sy, z)
    local metatile_header_size = 20 + 8 * 64 -- XXX: 532
    local x = tonumber(sx)
    local y = tonumber(sy)
    local header, err = fd:read(metatile_header_size)
    if header == nil then
        fd:close()
        ngx.log(ngx.ERR, "File read error: ",err)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    -- offset into lookup table in header
    --- XXX: metatile = 8
    local pib = 20 + ((y % 8) * 8) + ((x % 8) * 8 * 8 )
    local offset = get_offset(header, pib)
    local size = get_offset(header, pib+4)
    fd:seek("set", offset)
    local png, err = fd:read(size)
    if png == nil then
        fd:close()
        ngx.log(ngx.ERR, "File read error: ", err)
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    ngx.header.content_type = 'image/png'
    ngx.print(png)
    return
end

function send_imgfile(map, x, y, z)
    local imgfile = get_imgfilename(map, x, y, z)
    ngx.log(ngx.DEBUG, "Meta file path: ",imgfile)
    local fd, err = io.open(imgfile,"rb")
    if fd == nil then
        return nil
    else
        send_image(fd, x, y, z)
        fd:close()
    end
    return ngx.OK
end

-- function: get_imgfilename
-- arguments: string map
--            number x, y, z
-- return string filename
--
function get_imgfilename (map, x, y, z)
    local imgfile = tirextile
    if map == nil or map == "" then
        imgfile = imgfile..xyz_to_filename(x, y, z)
    else
        imgfile = imgfile..map.."/"..xyz_to_filename(x, y, z)
    end
    return imgfile
end


-- ---------------------------------------------------------------
-- The main routine
--
-- ---------------------------------------------------------------

-- init shared memory dictionay.
-- add keys when don't exist
function init_shmem()
    stats:add("http_requests", 0)
    stats:add("tiles_requested",0)
    stats:add("tiles_from_cache",0)
    stats:add("tiles_rendered",0)
end

-- main routine
--
--
init_shmem()
stats:incr("http_requests", 1)
local id = stats:incr("tiles_requested", 1)
if id == nil then
    ngx.log(ngx.WARN, "ngx.shared.Dict: stats access error")
    id = 0
end

-- try renderd file.
local ok = send_imgfile(map, x, y, z)
if ok then
    stats:incr("tiles_from_cache", 1)
    return ngx.OK
end

-- ask tirex to render it
local priority = 8
local ok = send_tile_tirex(map, x, y, z, priority, id)
if not ok then
   return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- vi:nosi:sw=4:ts=4
-- EOF --
