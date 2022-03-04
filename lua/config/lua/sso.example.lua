local http    = require "resty.http"
local json    = require("cjson")

local httpc = http.new()

local isapi = string.match( ngx.var.request_uri, '/api' )
if not isapi then
    return
end

if ngx.var.cookie_sid then
    if ngx.var.request_method == "GET" then

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

    else
        local res, err = httpc:request_uri(
            "http://OPENC3_SERVER_IP:88/api/connector/connectorx/point?point=openc3_job_root&cookie=" .. ngx.var.cookie_sid,
            {
                method = "GET",
                keepalive = false
            }
        )

        ngx.log(ngx.ERR, "PMS Connect!, cookie:[", ngx.var.cookie_sid,"]")

        local ret = json.decode(res.body)
        if ret then
            if ret.data and ret.stat == true and ( ret.data == 1 or ret.data == true ) then
                 ngx.log(ngx.ERR, "PMS Connect Faild!.cookie:", ngx.var.cookie_sid, "], user:[",ret.data ,"]")
                return
            end
        else
            ngx.log(ngx.ERR, "PMS Connect Faild!.cookie:", ngx.var.cookie_sid, "]")
        end

    end

end

ngx.log(ngx.ERR, "SSO Blocked!cookie:[", ngx.var.cookie_sid, "]")

ngx.exit(ngx.HTTP_UNAUTHORIZED)
