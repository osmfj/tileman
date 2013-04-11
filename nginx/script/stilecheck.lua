require "tilecheck"

if ngx.var.own_tile == "no" then
  return ngx.exec("@tilecache")
end
