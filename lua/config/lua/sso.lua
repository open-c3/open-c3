local http    = require "resty.http"
local json    = require("cjson")

local httpc = http.new()

if ngx.var.cookie_sid then
  local res, err = httpc:request_uri(
      "http://OPENC3_SERVER_IP:88/api/connector/connectorx/username?cookie=" .. ngx.var.cookie_sid,
      {
          method = "GET",
          keepalive = false
      }
  )

  ngx.log(ngx.ERR, "SSO Connect!, cookie:[", ngx.var.cookie_sid,"]")

  local ret = json.decode(res.body)
  if ret then
      if ret.data and ret.stat == true and ret.data.user and ret.data.user ~= ngx.null then
           ngx.log(ngx.ERR, "SSO Connect Faild!.cookie:", ngx.var.cookie_sid, "], user:[",ret.data.user ,"]")
          return
      end
  else
      ngx.log(ngx.ERR, "SSO Connect Faild!.cookie:", ngx.var.cookie_sid, "]")
  end
end

ngx.log(ngx.ERR, "SSO Blocked!cookie:[", ngx.var.cookie_sid, "]")

ngx.exit(ngx.HTTP_UNAUTHORIZED)
