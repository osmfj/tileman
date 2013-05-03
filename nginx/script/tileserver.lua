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

-- ---------------------------------------------------------------
-- Tirex Interface
--
-- ---------------------------------------------------------------
local tirexsock = 'unix:/var/run/tirex/master.sock'
local tirextile = "/var/lib/tirex/tiles/"
local tirex_shmem_timeout = 120 -- should be in sec
local stats = ngx.shared.stats


-- ------------------------------
-- Packet construction
--
-- ------------------------------

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

-- ------------------------------
-- Syncronize interface
--
-- ------------------------------

function get_key(map, mx, my, mz)
    return string.format("%s:%d:%d:%d",map, mx, my, mz)
end

-- function: register tirex handle
--    check whether other coroutine have already process with tirex
--    if not, register itself and return id
--    otherwise, return nil
--
--    ngx.shared.tirex
--       key: map:mz:my:z 
--       value:    0 - someone get handle
--                 1 - rendering successed
--
function get_handle(map, mx, my, z, id)
    local index = get_key(map, mx, my, z)
    return stats:safe_add(index, 0, tirex_shmem_timeout, id)
end

-- function: register_result
--
--    set shared.tirex to '1' - success
--
function send_signal(map, mx, my, z)
    local index = get_key(map, mx, my, z)
    return stats:incr(index, 1)
end

-- function: wait_result
--
--    check whether shared.tirex is '1' - success
--         if '0' - wait and check in 30 sec
--            '1' - return id
--
function wait_result(map, mx, my, mz)
    local index = get_key(map, mx, my, mz)
    for i=0, 5 do -- watch 30sec
        local val, id = stats:get(index)
        if val then
            if val > 0 then
                return id
            end
            ngx.sleep(5)
        else -- no waiting index... invalid
            return nil
        end
    end
    return nil
end

-- ------------------------------
-- socket interface
--
-- ------------------------------

-- function: request_tirex_render
--  enqueue request to tirex server thru unix domain socket datagram
--
function request_tirex_render(map, mx, my, mz, id)
    -- Create request command
    local priority = 8
    local req = serialize_tirex_msg({
        ["id"]   = tostring(id);
        ["type"] = 'metatile_enqueue_request';
        ["prio"] = priority;
        ["map"]  = map;
        ["x"]    = mx;
        ["y"]    = my;
        ["z"]    = mz})

    -- send request to Tirex master socket
    local udpsock = ngx.socket.udp()
    local socketpath = tirexsock
    local ok, err = udpsock:setpeername(socketpath)
    if not ok then
        ngx.log(ngx.ERR, "udpsock setpeername error")
        return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end
    udpsock:send(req)
    local data, err = udpsock:receive()
    if not data
        ngx.log(ngx.ERR, "timeout ", mx, " ", my, " ", mz)
        return nil
    end
    udpsock:close()

    -- check result
    local msg = deserialize_tirex_msg(tostring(data))
    if not msg then -- something wrong
        return nil
    end
    if msg["result"] ~= "ok" then
        return nil
    end
    return ngx.OK
end

-- ------------------------------
-- control request
--
-- ------------------------------

-- funtion: send_tirex_request
-- argument: map, x, y, z
-- return:   if ok ngx.OK, if not ok then nil
--
function send_tirex_request (map, x, y, z)
    local mx = x - x % 8
    local my = y - y % 8
    local mz = z
    local id = ngx.time()
    local ok, err = get_handle(map, mx, my, z, id)
    if not ok then
        -- someone have already start Tirex session
        -- wait other side(*), sync..
        return wait_result(map, mx, my, mz)
    end
    -- Start Tirex session
    local ok = request_tirex_render(map, mx, my, mz, id)
    if not ok then
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    -- We got new metatile. signal to who waiting above(*)
    local ok,err = send_signal(map, mx, my, mz)
    if not ok then
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    return ngx.OK
end



-- ---------------------------------------------------------------
-- Metatile routines
--
-- ---------------------------------------------------------------

-- function: xyz_to_filename
-- arguments: int x, y, z
-- return: filename of metatile
--
function xyz_to_filename (x, y, z) 
    local res=''
    local v = 0
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

-- function send_tile
-- arguments map, x, y, z
-- return ngx.OK or nil
-- 
--  send back tile to client from metatile
--
function send_tile(map, x, y, z)
    local imgfile = get_imgfilename(map, x, y, z)
    local fd, err = io.open(imgfile,"rb")
    if fd == nil then
        return nil
    end
    local metatile_header_size = 532 -- XXX: 20 + 8 * 64
    local header, err = fd:read(metatile_header_size)
    if header == nil then
        fd:close()
        ngx.log(ngx.ERR, "File read error: ",err)
        return nil
    end
    -- offset: lookup table in header
    local pib = 20 + ((y % 8) * 8) + ((x % 8) * 8 * 8 )
    local offset = get_offset(header, pib)
    local size = get_offset(header, pib+4)
    fd:seek("set", offset)
    local png, err = fd:read(size)
    if png == nil then
        fd:close()
        ngx.log(ngx.ERR, "File read error: ", err)
        return nil
    end
    ngx.header.content_type = 'image/png'
    ngx.print(png)
    fd:close()
    return ngx.OK
end

-- ---------------------------------------------------------------
-- The main routine
--
-- ---------------------------------------------------------------
-- main routine
-- vals from nginx conf
--
local map = ngx.var.map
local x = tonumber(ngx.var.x)
local y = tonumber(ngx.var.y)
local z = tonumber(ngx.var.z)

-- try renderd file.
local ok = send_tile(map, x, y, z)
if ok then
    return ngx.OK
end

-- ask tirex to render it
local ok = send_tirex_request(map, x, y, z)
if not ok then
   return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local ok = send_tile(map, x, y, z)
if not ok then
    return ngx.exit(ngx.HTTP_NOT_FOUND)
end

return ngx.OK

-- vi:nosi:sw=4:ts=4
-- EOF --
