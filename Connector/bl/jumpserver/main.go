package main

import (
	"bl/src/bastion"
	"flag"
)

func main() {
	user := flag.String("user", "", "jumpsever堡垒机管理员登陆账号")
	pass := flag.String("pass", "", "jumpsever堡垒机管理员登陆密码")
	url := flag.String("url", "", "jumpsever堡垒机地址, 比如 http://192.168.3.31:80")

	flag.Parse()

	if *user == "" || *pass == "" || *url == "" {
		panic("-user、-pass、-url等参数不允许为空")
	}

	bastion.SyncMachines(*user, *pass, *url)
}
