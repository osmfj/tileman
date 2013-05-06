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
-- Utility functions
--
-- serialize/deserialize
-- bet table <-> string 
-- ---------------------------------------------------------------

-- function: serialize_msg
-- argument: table msg
--     hash table {key1=val1, key2=val2,....}
-- return: string
--     should be 'key1=val1\nkey2=val2\n....\n'
--
function serialize_msg (msg)
    local str = ''
    for k,v in pairs(msg) do
        str = str .. k .. '=' .. tostring(v) .. '\n'
    end
    return str
end

-- function: deserialize_msg
-- arguments: string str: recieved message from tirex
--     should be 'key1=val1\nkey2=val2\n....\n'
-- return: table
--     hash table {key1=val1, key2=val2,....}
function deserialize_msg (str) 
    local msg = {}
    for line in string.gmatch(str, "[^\n]+") do
        m,_,k,v = string.find(line,"([^=]+)=(.+)")
        if  k ~= '' then
            msg[k]=v
        end
    end
    return msg
end


-- ------------------------------------
-- Syncronize thread functions
--
--   thread(1)
--       get_handle(key)
--       do work
--       store work result somewhere
--       send_signal(key)
--       return result
--
--   thread(2)
--       get_handle(key) fails then
--       wait_singal(key)
--       return result what thread(1) done
--
--   to syncronize amoung nginx threads
--   we use ngx.shared.DICT interface.
--   
--   Here we use ngx.shared.stats
--   you need to set /etc/conf.d/lua.conf
--      ngx_shared_dict stats 10m; 
--
--   if these functions returns 'nil'
--   status is undefined
--   something wrong
--
--   status definitions
--    key is not exist:    neutral
--    key is exist: someone got work token
--       val = 0:     now working
--       val > 0:     work is finished
--
--    key will be expired in timeout sec
--    we can use same key after timeout passed
--
-- ------------------------------------

--
--  if key exist, it returns false
--  else it returns true
--
function get_handle(key,timeout, flag)
    local stats = ngx.shared.stats
    local success,err,forcible = stats:add(key, 0, timeout, flag)
    if success ~= false then
        return key, ''
    end
    return nil, ''
end

-- returns new value (maybe 1)
function send_signal(key)
    local stats = ngx.shared.stats
    return stats:incr(key, 1)
end

-- return nil if timeout in wait
--
function wait_signal(key,timeout)
    local stats = ngx.shared.stats
    local interval = 1
    local timeout = tonumber(timeout)
    for i=0, timeout do
        local val, id = stats:get(key)
        if val then
            if val > 0 then
                return id
            end
            ngx.sleep(interval)
        else
            return nil
        end
    end
    return nil
end

-- ---------------------------------------------------------------
-- Tirex Interface
--
-- ---------------------------------------------------------------

local tirextile = "/var/lib/tirex/tiles/"
local tirex_sync_duration = 240 -- should be in sec

-- ========================================================
--  It does not share context and global vals/funcs
--
local tirex_handler
tirex_handler = function (premature)
    local tirexsock = 'unix:/var/run/tirex/master.sock'
    local tirex_cmd_max_size = 512
    local tirex_resp_timeout = 20000
    
    local cmds = ngx.shared.cmds
    local stats = ngx.shared.stats
    
    local indexes = cmds:get_keys()
    local udpsock = ngx.socket.udp()
    udpsock:settimeout(tirex_resp_timeout)
    udpsock:setpeername(tirexsock)

    for key,index in pairs(indexes) do
        -- send/receive request
        local req = cmds:get(index)
        udpsock:send(req)
        local data, err = udpsock:receive(tirex_cmd_max_size)
        if not data then
            ngx.log(ngx.INFO, "receive error", err)
        end

   -- deserialize
        local msg = {}
        for line in string.gmatch(data, "[^\n]+") do
            m,_,k,v = string.find(line,"([^=]+)=(.+)")
            if  k ~= '' then
                msg[k]=v
            end
        end

        local resp = string.format("%s:%d:%d:%d", msg["map"], msg["x"], msg["y"], msg["z"])

   -- send_signal to client context
        ok, err = stats:incr(resp, 1)
        if not ok then
            ngx.log(ngx.INFO, "error in incr")
        end
        cmds:delete(resp)
    end
    udpsock:close()
    --
    -- call myself daemonized 
    ngx.timer.at(0.01, tirex_handler)
end
-- ========================================================

function push_request_tirex_render(index,req)
    local cmds = ngx.shared.cmds
    return cmds:safe_add(index, req, 0, 0)
end

function start_handler_if_needed()
    local handle = get_handle('_tirex_handler', 0, 0)
    if handle then
        -- only single light thread can handle Tirex
        ngx.log(ngx.INFO, "start tirex_handler")
        ngx.timer.at(0, tirex_handler)
    end
end

-- function: request_tirex_render
--  enqueue request to tirex server
--
function request_tirex_render(map, mx, my, mz, id)
    -- Create request command
    local index = string.format("%s:%d:%d:%d",map, mx, my, mz)
    local priority = 8
    local req = serialize_msg({
        ["id"]   = tostring(id);
        ["type"] = 'metatile_enqueue_request';
        ["prio"] = priority;
        ["map"]  = map;
        ["x"]    = mx;
        ["y"]    = my;
        ["z"]    = mz})
    push_request_tirex_render(index, req)
    start_handler_if_needed()
    return ngx.OK
end

-- funtion: send_tirex_request
-- argument: map, x, y, z
-- return:   if ok ngx.OK, if not ok then nil
--
function send_tirex_request (map, x, y, z)
    local mx = x - x % 8
    local my = y - y % 8
    local mz = z
    local id = ngx.time()
    local index = string.format("%s:%d:%d:%d",map, mx, my, mz)

    local ok, err = get_handle(index, tirex_sync_duration, id)
    if not ok then
        -- someone have already start Tirex session
        -- wait other side(*), sync..
        return wait_signal(index, 30)
    end

    -- Ask Tirex session
    local ok = request_tirex_render(map, mx, my, mz, id)
    if not ok then
        return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end
    return wait_signal(index, 30)
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
