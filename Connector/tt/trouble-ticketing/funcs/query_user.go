package funcs

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
)

// 用户信息
type UserInfo struct {
	AccountId   string `json:"accountId"`
	Mobile      string `json:"mobile"`
	AccountName string `json:"accountName"`
	OneDeptName string `json:"oneDeptName"`
	SybDeptName string `json:"sybDeptName"`
}

func GetUserInfo(user string) (UserInfo, error) {
	var res UserInfo
	userinfo, err := queryUser(user)
	if err != nil {
		PrintlnLog(fmt.Sprintf("GetUserInfo.queryUser.err: %v", err))
		return res, err
	}
	userinfo, err = yamlToJson(userinfo)
	if err != nil {
		PrintlnLog(fmt.Sprintf("GetUserInfo.yamlToJson.err: %v", err))
		return res, err
	}
	err = json.Unmarshal([]byte(userinfo), &res)
	if err != nil {
		PrintlnLog(fmt.Sprintf("GetUserInfo.Unmarshal.err: %v", err))
		return res, err
	}
	return res, nil
}

func queryUser(user string) (string, error) {
	cmd := exec.Command("c3mc-base-userinfo", "-u", user)

	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		PrintlnLog(fmt.Sprintf("queryUser.Run.err: %v, cmd.err: %v", err, stderr.String()))
		return "", err
	}
	return out.String(), nil
}

func yamlToJson(yaml string) (string, error) {
	cmd := exec.Command("yaml2json")
	cmd.Stdin = strings.NewReader(yaml)

	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		PrintlnLog(fmt.Sprintf("yamlToJson.Run.err: %v, cmd.err: %v", err, stderr.String()))
		return "", err
	}
	return out.String(), nil
}
