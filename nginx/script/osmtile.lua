--
-- Lua access script for providing osm tile cache
--
-- requisite: lua-resty-redis, socket
--
      if ngx.var.uri:sub(-4) ~= ".png" then
        ngx.exit(ngx.HTTP_FORBIDDEN)
      end

      local captures = "/(%d+)/(%d+)/(%d+).png"
      local s,_,z,x,y = ngx.var.uri:find(captures)
      if s == nil then
        ngx.exit(ngx.HTTP_NOT_FOUND)
      end

      if ngx.var.own_tile == 'no' then
        return ngx.exec("@tilecache")
      end

      local redis = require "resty.redis"
      local red = redis:new()

      red:set_timeout(1000) -- 1 sec

      -- local ok, err = red:connect("unix:/var/run/redis/redis.sock")

      local ok, err = red:connect("127.0.0.1", 6379)
      if not ok then
        -- cannot connect redis server
        -- ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        return
      end

      --    key; val 
      -- counter   "c:x:y:z" ; counter
      -- avail     "a:x:y:z" ; expirity "d" dirty, "f" fresh
      -- requested "r:x:y:z" ; latest request date/time

      local kindex = string.format("%d:%d:%d",x,y,z)
      red:init_pipeline()
      red:incr("c:"..kindex)
      red:set("r:"..kindex, os.time())
      red:get("a:"..kindex)
      local results, err = red:commit_pipeline()
      if not results then
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
      end
      for i, res in ipairs(results) do
        if type(res) == "table" then
          if not res[1] then
            return
          end
        else
          if i == 3 then
            ares = res
          end
        end
     end

     if ares == ngx.null then
       -- no record exist
       -- ask backend to render it if capable
     end

      -- check tile freshness
      -- tile expiry check
      -- "d" means need render/dirty
      -- "f" means fresh

      if ares == "d" then
         -- call renderd with x/y/z here
      end

      -- put it into the connection pool of size 100,
      -- with 0 idle timeout
      local ok, err = red:set_keepalive(0, 100)
      if not ok then
        -- ignore it
        return
      end
