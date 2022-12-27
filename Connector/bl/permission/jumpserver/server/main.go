package main

import (
	"flag"
	"fmt"
	"os"
	"permisstion/src"
	"strconv"
)

func main() {
	ip := flag.String("ip", "", "IP")
	sshUser := flag.String("ssh_user", "", "ssh用户")
	sshPort := flag.String("ssh_port", "", "ssh端口")
	// 该服务在类似跳板机这种服务器上执行，这里的私钥地址是可以无密码登陆目标服务器的ssh用户的私钥地址
	privateKeyPath := flag.String("private_key_path", "", "私钥地址")
	addType := flag.String("add_type", "", "权限处理类型。1: 添加普通权限; 2: 删除普通权限; 3: 添加sudo权限; 4: 删除sudo权限(保留账户); 5: 删除sudo权限(不保留账户)")
	userName := flag.String("username", "", "目标用户账户")
	userPass := flag.String("userpass", "", "目标用户密码")
	ifKeepHome := flag.String("if_keep_home", "", "删除用户时是否需要保留用户主目录。0: 不保留; 1: 保留")

	flag.Parse()

	if *ip == "" {
		fmt.Fprintln(os.Stderr, "-ip参数必传")
		return
	}
	if *sshUser == "" {
		fmt.Fprintln(os.Stderr, "-ssh_user参数必传")
		return
	}
	if *sshPort == "" {
		fmt.Fprintln(os.Stderr, "-ssh_port参数必传")
		return
	}
	if *privateKeyPath == "" {
		fmt.Fprintln(os.Stderr, "-private_key_path参数必传")
		return
	}
	if *addType == "" {
		fmt.Fprintln(os.Stderr, "-add_type参数必传")
		return
	}
	if *userName == "" {
		fmt.Fprintln(os.Stderr, "-username参数必传")
		return
	}
	if *userPass == "" {
		fmt.Fprintln(os.Stderr, "-userpass参数必传")
		return
	}
	if *ifKeepHome == "" {
		fmt.Fprintln(os.Stderr, "-if_keep_home参数必传")
		return
	}

	sshPortNumber, err := strconv.Atoi(*sshPort)
	if err != nil {
		panic(err)
	}

	per, err := src.NewSshClient(*sshUser, *ip, sshPortNumber, *privateKeyPath)
	if err != nil {
		panic(err)
	}

	//1: 添加普通权限; 2: 删除普通权限; 3: 添加sudo权限; 4: 删除sudo权限(保留账户); 5: 删除sudo权限(不保留账户)
	switch *addType {
	case "1", "3":
		if *userName == "" || *userPass == "" {
			panic("-username、-userpass等选项参数必传")
		}
		if *addType == "1" {
			_, err = per.AddNormalPrivilege(*userName, *userPass)
			if err != nil {
				panic(err)
			}
		} else {
			_, err = per.AddSudoPrivilege(*userName, *userPass)
			if err != nil {
				panic(err)
			}
		}
		return
	case "2", "5":
		// 删除普通权限按照删除sudo权限的方式执行
		// 如果普通权限都删了，留着sudo权限也没意义
		if *userName == "" || *ifKeepHome == "" {
			panic("-username、-if_keep_home等选项参数必传")
		}
		ifKeepHomeDir := true
		if *ifKeepHome == "0" {
			ifKeepHomeDir = false
		}
		_, err = per.DelSudoPrivilege(*userName, ifKeepHomeDir)
		if err != nil {
			panic(err)
		}
	case "4":
		if *userName == "" {
			panic("-username等选项参数必传")
		}
		output, err := per.DelJustSudoPrivilege(*userName)
		if err != nil {
			panic(fmt.Sprintf("output: %v, err: %v", *output, err))
		}
	}
}
