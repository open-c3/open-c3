package main

import (
	"bl/src/bastion"
	"flag"
)

func main() {
	user := flag.String("user", "", "jumpsever堡垒机管理员登陆账号")
	pass := flag.String("pass", "", "jumpsever堡垒机管理员登陆密码")
	url := flag.String("url", "", "jumpsever堡垒机地址, 比如 http://192.168.3.31:80")
	appName := flag.String("appname", "", "获取接口数据的凭据名称")
	appKey := flag.String("appkey", "", "获取接口数据的凭据密码")

	flag.Parse()

	if *user == "" || *pass == "" || *url == "" || *appName == "" || *appKey == "" {
		panic("所有参数必传")
	}

	bastion.SyncMachines(*user, *pass, *url, *appName, *appKey)
}
