local http = require "resty.http"
local json = require("cjson")

local httpc = http.new()

local  isapi = string.match( ngx.var.request_uri, '/api' )
if not isapi then
    return
end

if ngx.var.cookie_sid then
    local readonly = false

    if ngx.var.request_method == "GET" then
        readonly = true
    end

    local  getseries = string.match( ngx.var.request_uri, 'resources/api/v1/series' )
    if getseries then
        readonly = true
    end

    if readonly then

        local res, err = httpc:request_uri(
            "http://OPENC3_SERVER_IP:88/api/connector/connectorx/username?cookie=" .. ngx.var.cookie_sid,
            {
                method    = "GET",
                keepalive = false
            }
        )

        if not err == nil then
            ngx.log(ngx.ERR, "SSO Connect Faild!.cookie:", ngx.var.cookie_sid, "] Error[", err "]")
        end

        local ret = json.decode(res.body)
        if ret then
            if ret.data and ret.stat == true and ret.data.user and ret.data.user ~= ngx.null then
                return
            end
        else
            ngx.log(ngx.ERR, "SSO Connect Faild!.cookie:", ngx.var.cookie_sid, "]")
        end

    else
        local res, err = httpc:request_uri(
            "http://OPENC3_SERVER_IP:88/api/connector/connectorx/point?point=openc3_job_root&cookie=" .. ngx.var.cookie_sid,
            {
                method    = "GET",
                keepalive = false
            }
        )

        if not err == nil then
            ngx.log(ngx.ERR, "PMS Connect Faild!.cookie:", ngx.var.cookie_sid, "] Error[", err "]")
        end

        local ret = json.decode(res.body)
        if ret then
            if ret.data and ret.stat == true and ( ret.data == 1 or ret.data == true ) then
                return
            end
        else
            ngx.log(ngx.ERR, "PMS Connect Faild!.cookie:", ngx.var.cookie_sid, "]")
        end

    end

end

ngx.exit(ngx.HTTP_UNAUTHORIZED)
