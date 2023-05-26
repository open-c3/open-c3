# 使用https

```
Open-C3启动后默认是一个80端口的http服务。
如果你需要https的协议，请用一个nginx进行转发,把Open-C3的80端口作为后端。

配置过程中需要注意如下几个代理的配置字段：

# 把协议传递到后端，影响到keycloak的功能,配置错误会导致keycloak登录页打开失败。
proxy_set_header X-Forwarded-Proto $scheme;

# 把用户IP传递到后端，影响登录审计
# Open-C3会记录用户的登录IP，同时IP频繁登录失败时会自动临时限制IP登录。
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

# 长连接,影响日志展示
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";

```

## nginx https配置的例子

```
server {

        listen       443 ssl;
        server_name  open-c3.domain.org;

        #ssl证书文件位置(常见证书文件格式为：crt/pem)
        ssl_certificate      /etc/nginx/csr/domain.org_nginx/domain.org_bundle.crt;
        #ssl证书key位置
        ssl_certificate_key  /etc/nginx/csr/domain.org_nginx/domain.org.key;

        #ssl配置参数（选择性配置）
        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;
        #数字签名，此处使用MD5
        ssl_ciphers  HIGH:!aNULL:!MD5;

        location /third-party/keycloak/ {
               include /etc/nginx/allow.d/ip.conf;

                proxy_set_header  X-Forwarded-For $remote_addr;
                proxy_set_header  X-Forwarded-Proto $scheme;
                proxy_set_header  X-Real-IP $remote_addr;
                proxy_set_header  Host $host;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";

                proxy_pass http://open-c3.domain.org;
        }

        location / {

                proxy_set_header  X-Forwarded-For $remote_addr;
                proxy_set_header  X-Forwarded-Proto $scheme;
                proxy_set_header  X-Real-IP $remote_addr;
                proxy_set_header  Host $host;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";

                proxy_pass http://open-c3.domain.org;

        }

        location ~ ^/status/ {
                stub_status on;
                access_log off;
        }

        error_page  404              /404.html;
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
                root   html;
        }

}

```
