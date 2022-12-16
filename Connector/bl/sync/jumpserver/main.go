package main

import (
	"bl/src/bastion"
	"os"
)

func main() {
	// 参数的含义是 管理员账户、管理员密码、jumpserver地址、appName、appKey
	bastion.SyncMachines(os.Args[1], os.Args[2], os.Args[3], os.Args[4], os.Args[5])
}
