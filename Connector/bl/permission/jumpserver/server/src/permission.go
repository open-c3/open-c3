package src

import (
	"fmt"
)

// AddNormalPrivilege 添加普通权限
func (s *SshClient) AddNormalPrivilege(username, password string) (*string, error) {
	command := fmt.Sprintf("sudo useradd %v", username)
	output, err := s.RunCommand(command)
	fmt.Printf("AddNormalPrivilege.useradd. command: %v, output: %v, err: %v\n", command, *output, err)

	command = fmt.Sprintf("echo %v | sudo passwd --stdin %v", password, username)
	output, err = s.RunCommand(command)
	fmt.Printf("AddNormalPrivilege.passwd. command: %v, output: %v, err: %v\n", command, *output, err)

	command = fmt.Sprintf("cat /etc/passwd | awk -F ':' '{print$1}'| grep -w %v | wc -l", username)
	output, err = s.RunCommand(command)
	fmt.Printf("AddNormalPrivilege.check. command: %v, output: %v, err: %v\n", command, *output, err)
	return output, nil
}

// DelNormalPrivilege 删除普通权限
func (s *SshClient) DelNormalPrivilege(username string, ifKeepHome bool) (*string, error) {
	command := fmt.Sprintf("sudo killall -u %v", username)
	output, err := s.RunCommand(command)
	fmt.Printf("DelNormalPrivilege.userdel. killall command: %v, output: %v, err: %v\n", command, *output, err)

	command = fmt.Sprintf("sudo userdel -f -r %v", username)
	if ifKeepHome {
		command = fmt.Sprintf("sudo userdel -f %v", username)
	}
	output, err = s.RunCommand(command)
	fmt.Printf("DelNormalPrivilege.userdel. userdel command: %v, output: %v, err: %v\n", command, *output, err)
	return output, nil
}

// AddSudoPrivilege 添加sudo权限
func (s *SshClient) AddSudoPrivilege(username, password string) (*string, error) {
	output, err := s.AddNormalPrivilege(username, password)
	if err != nil {
		fmt.Printf("AddSudoPrivilege.AddNormalPrivilege. err: %v\n", err)
		return nil, err
	}
	fmt.Printf("AddSudoPrivilege.AddNormalPrivilege. output: %v\n", *output)

	command := fmt.Sprintf("sudo gpasswd -a %v wheel>/dev/null 2>&1", username)
	output, err = s.RunCommand(command)
	fmt.Printf("AddSudoPrivilege.gpasswd. command: %v, output: %v, err: %v\n", command, *output, err)

	command = fmt.Sprintf("cat /etc/group | grep wheel | grep -w %v |wc -l", username)
	output, err = s.RunCommand(command)
	fmt.Printf("AddSudoPrivilege.check. command: %v, output: %v, err: %v\n", command, *output, err)

	return output, nil
}

// DelJustSudoPrivilege 删除sudo权限(保留账户)
func (s *SshClient) DelJustSudoPrivilege(username string) (*string, error) {
	command := fmt.Sprintf("sudo gpasswd -d %v wheel", username)
	output, err := s.RunCommand(command)
	fmt.Printf("DelJustSudoPrivilege.gpasswd. command: %v, output: %v, err: %v", command, *output, err)

	command = fmt.Sprintf("cat /etc/group | grep wheel | grep -w %v |wc -l", username)
	output, err = s.RunCommand(command)
	fmt.Printf("DelJustSudoPrivilege.check. command: %v, output: %v, err: %v", command, *output, err)
	return output, nil
}

// DelSudoPrivilege 删除sudo权限(不保留账户)
func (s *SshClient) DelSudoPrivilege(username string, ifKeepHome bool) (*string, error) {
	output, err := s.DelJustSudoPrivilege(username)
	if err != nil {
		fmt.Printf("DelSudoPrivilege.DelJustSudoPrivilege. err: %v", err)
		return nil, err
	}
	fmt.Printf("DelSudoPrivilege.DelJustSudoPrivilege. output: %v", *output)

	output, err = s.DelNormalPrivilege(username, ifKeepHome)
	if err != nil {
		fmt.Printf("DelSudoPrivilege.DelNormalPrivilege. err: %v", err)
		return nil, err
	}
	fmt.Printf("DelSudoPrivilege.DelNormalPrivilege. output: %v", *output)
	return output, nil
}
