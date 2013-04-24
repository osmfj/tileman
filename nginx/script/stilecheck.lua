require "tilecheck"

if ngx.var.own_tile == "no" then
  return ngx.exit(ngx.HTTP_NOT_ALLOWED)
end
