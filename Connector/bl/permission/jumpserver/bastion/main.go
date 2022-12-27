package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"permisstion/src"
)

func main() {
	adminUser := flag.String("admin_user", "", "jumpsever堡垒机管理员登陆账号")
	adminPass := flag.String("admin_pass", "", "jumpsever堡垒机管理员登陆密码")
	url := flag.String("url", "", "jumpsever堡垒机地址, 比如 http://192.168.3.31:80")
	username := flag.String("username", "", "需要添加服务器权限的目标账户")
	email := flag.String("email", "", "需要添加服务器权限的目标账户邮箱")
	ip := flag.String("ip", "", "需要添加服务器权限的目标IP")
	sshPort := flag.String("ssh_port", "", "Port")
	sshUser := flag.String("ssh_user", "", "ssh用户")
	addType := flag.String("add_type", "", "权限处理类型。1: 添加普通权限; 2: 删除普通权限; 3: 添加sudo权限; 4: 删除sudo权限(保留账户); 5: 删除sudo权限(不保留账户)")
	ifKeepHome := flag.String("if_keep_home", "", "删除用户时是否需要保留用户主目录。0: 不保留; 1: 保留")
	privateKeyPath := flag.String("private_key_path", "", "私钥地址")

	flag.Parse()

	if *adminUser == "" {
		fmt.Fprintln(os.Stderr, "-admin_user参数必传")
		return
	}
	if *adminPass == "" {
		fmt.Fprintln(os.Stderr, "-admin_pass参数必传")
		return
	}
	if *url == "" {
		fmt.Fprintln(os.Stderr, "-url参数必传")
		return
	}
	if *username == "" {
		fmt.Fprintln(os.Stderr, "-username参数必传")
		return
	}
	if *email == "" {
		fmt.Fprintln(os.Stderr, "-email参数必传")
		return
	}
	if *ip == "" {
		fmt.Fprintln(os.Stderr, "-ip参数必传")
		return
	}
	if *sshPort == "" {
		fmt.Fprintln(os.Stderr, "-ssh_port参数必传")
		return
	}
	if *sshUser == "" {
		fmt.Fprintln(os.Stderr, "-ssh_user参数必传")
		return
	}
	if *addType == "" {
		fmt.Fprintln(os.Stderr, "-add_type参数必传")
		return
	}
	if *ifKeepHome == "" {
		fmt.Fprintln(os.Stderr, "-if_keep_home参数必传")
		return
	}
	if *privateKeyPath == "" {
		fmt.Fprintln(os.Stderr, "-private_key_path参数必传")
		return
	}

	b, err := src.NewBastion(*adminUser, *adminPass, *url)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return
	}

	var (
		systemUserPassword = "xxx"
		output             string
	)
	switch *addType {
	// 1.添加普通权限、3.添加sudo权限
	case "1", "3":
		resp, err := b.AttachIpToUser(*username, *email, *ip)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}
		systemUserPassword = resp.SystemUserPassword

		br, _ := json.Marshal(resp)
		output = string(br)
	// 2.删除针对ip的普通权限、4.删除sudo权限(保留账户)、5.删除sudo权限(不保留账户)
	case "2", "4", "5":
		permission, err := b.GetAssetPermissions(*username)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}
		err = b.RemoveAssetPermissionForAssetId(permission, *username, *ip)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			return
		}
	}

	command := fmt.Sprintf("jumpserver-server -ip %v -ssh_port %v -ssh_user %v -add_type %v -username %v -userpass '%v' -private_key_path %v -if_keep_home %v",
		*ip,
		*sshPort,
		*sshUser,
		*addType,
		*username,
		systemUserPassword,
		*privateKeyPath,
		*ifKeepHome,
	)

	cmd := exec.Command("bash", "-c", command)
	_, err = cmd.Output()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return
	}

	fmt.Println(output)
}
