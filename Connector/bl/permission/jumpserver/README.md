# 通过jumpserver添加服务器访问权限

该命令保存在类似跳板机这种服务器上，主要是有两个要求:
1. 要能够访问 jumpserver 服务
2. 要能通过当前用户 (部署jumpserver服务的用户) ssh无密码登陆目标服务器, 且登陆后允许无密码执行sudo
