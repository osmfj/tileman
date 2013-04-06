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
function serialize_tirex_msg (msg) 
    local str = ''

    for k,v in pairs(msg) do
        str = str .. k .. '=' .. v .. '\n'
    end
    
    return str
end

function deserialize_tirex_msg (str) 
    local msg = {}
    for line in string.gmatch(str, "[^\n]+") do
        m,k,v = string.find(line,"([^=]+)=(.+)") do
        if  k ~= '' then
            table.insert(msg, {k,v})
        end
    end

    return msg;
end

function xyz_to_filename (x, y, z) 
    local res=''

    -- make sure we have metatile coordinates
    x = x - x % 8
    y = y - y % 8

    for i=0, 4 do
        v = x & 0x0f
        v = v << 4
        v = v | (y & 0x0f)
        x = x >> 4
        y = y >> 4
        res = res .. tostring(v) .. '/'
    end

    return res .. tostring(z) .. '.meta'
end

local metatile_header_size = 20 + 8 * 64

ngx.shared.stats:incr("http_requests", 1)
--ngx.shared.stats:incr("tiles_requested", 1)
--ngx.shared.stats:incr("tiles_from_cache", 1)
--ngx.shared.stats.incr("tiles_rendered", 1)

local config = {
    {"configdir",'/etc/tirex'},
    {"master_udp_port", 9322}
    {"tileserver_http_port", 9320}}


