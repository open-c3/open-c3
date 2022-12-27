package src

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"
)

type Bastion struct {
	url   string
	token string
}

func NewBastion(user, pass, url string) (*Bastion, error) {
	apiUrl, err := GetUrlWithParams(url, "/api/v1/authentication/auth/", nil)
	if err != nil {
		FsErrorf("NewBastion.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	postData := ToJsonString(AuthenticateBody{
		Username: user,
		Password: pass,
	})

	header := map[string]string{
		"Content-Type": "application/json",
	}

	var resp AuthenticateResponse
	body, _, err := DoNetworkRequest(http.MethodPost, *apiUrl, postData, header, &resp)
	if err != nil {
		FsErrorf("NewBastion.DoNetworkRequest.err: %v", err)
		return nil, err
	}
	if len(body) > 0 && (strings.Contains(string(body), "password_failed") || strings.Contains(string(body), "block_login")) {
		type errResp struct {
			Err error  `json:"err"`
			Msg string `json:"msg"`
		}
		var er errResp
		err = json.Unmarshal(body, &er)
		if err != nil {
			FsErrorf("NewBastion.Unmarshal.err: %v", err)
			return nil, err
		}
		return nil, errors.New(er.Msg)
	}
	return &Bastion{url: url, token: resp.Token}, nil
}

func (b *Bastion) getHeader() map[string]string {
	return map[string]string{
		"Authorization": fmt.Sprintf("Bearer %v", b.token),
		"Content-Type":  "application/json",
	}
}

// 检查用户是否存在
func (b *Bastion) getUser(username string) (*User, error) {
	apiUrl, err := GetUrlWithParams(
		b.url,
		"/api/v1/users/users/",
		map[string]string{
			"username": username,
			"name":     username,
		},
	)
	if err != nil {
		FsErrorf("checkIfUserExist.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	var r []User

	body, _, err := DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), &r)
	if err != nil {
		FsErrorf("checkIfUserExist.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return nil, err
	}
	if len(r) == 0 {
		return nil, nil
	}
	return &r[0], nil
}

func (b *Bastion) checkIfUserDuplicate(username, email string) (*bool, error) {
	apiUrl, err := GetUrlWithParams(
		b.url,
		"/api/v1/users/users/",
		map[string]string{
			"username": username,
			"name":     username,
			"email":    email,
		},
	)
	if err != nil {
		FsErrorf("checkIfUserDuplicate.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	var r []User

	body, _, err := DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), &r)
	if err != nil {
		FsErrorf("checkIfUserDuplicate.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return nil, err
	}
	exist := len(r) > 0
	return &exist, nil
}

// 创建用户
func (b *Bastion) createUser(username, email, password string) error {
	exist, err := b.checkIfUserDuplicate(username, email)
	if err != nil {
		FsErrorf("createUser.checkIfUserDuplicate.err: %v", err)
		return err
	}
	if *exist {
		errMsg := "用户名或邮箱已存在"
		return errors.New(errMsg)
	}

	apiUrl, err := GetUrlWithParams(
		b.url,
		"/api/v1/users/users/",
		nil,
	)
	if err != nil {
		FsErrorf("createUser.GetUrlWithParams.err: %v", err)
		return err
	}

	data := ToJsonString(CreateUserRequest{
		Username:           username,
		Name:               username,
		Email:              email,
		MfaLevel:           0,
		NeedUpdatePassword: false,
		Password:           password,
		PasswordStrategy:   "custom",
		//Phone:              phone,
		Source:      "local",
		SystemRoles: []string{"00000000-0000-0000-0000-000000000003"},
	})

	body, _, err := DoNetworkRequest(http.MethodPost, *apiUrl, data, b.getHeader(), nil)
	if err != nil {
		FsErrorf("createUser.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}
	return nil
}

// 获取资产信息
func (b *Bastion) getAsset(ip string) (*Asset, error) {
	apiUrl, err := GetUrlWithParams(
		b.url,
		"/api/v1/assets/assets/",
		map[string]string{
			"ip": ip,
		},
	)
	if err != nil {
		FsErrorf("getAsset.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	var r []Asset

	body, _, err := DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), &r)
	if err != nil {
		FsErrorf("getAsset.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return nil, err
	}

	if len(r) == 0 {
		return nil, nil
	}
	return &r[0], nil
}

// 创建系统用户。一个系统用户只会给一个用户加IP组合使用
//
// 这里规定，系统用户的用户名格式为 "用户名_Ip"
func (b *Bastion) createSystemUser(username, ip, password string) error {
	err := b.deleteSystemUser(username, ip)
	if err != nil {
		FsErrorf("createSystemUser.deleteSystemUser.err: %v", err)
		return err
	}

	apiUrl, err := GetUrlWithParams(
		b.url,
		"/api/v1/assets/system-users/",
		nil,
	)
	if err != nil {
		FsErrorf("createSystemUser.GetUrlWithParams.err: %v", err)
		return err
	}

	data := ToJsonString(CreateSystemUserRequest{
		AutoGenerateKey:      false,
		AutoPush:             false,
		Home:                 fmt.Sprintf("/home/%v", username),
		LoginMode:            "auto",
		Name:                 fmt.Sprintf("%v_%v", username, ip),
		Priority:             81,
		Protocol:             "ssh",
		SftpRoot:             "tmp",
		Shell:                "/bin/bash",
		SuEnabled:            false,
		Sudo:                 "/bin/whoami",
		Username:             username,
		Password:             password,
		UsernameSameWithUser: false,
	})

	body, _, err := DoNetworkRequest(http.MethodPost, *apiUrl, data, b.getHeader(), nil)
	if err != nil {
		FsErrorf("createSystemUser.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}
	return nil
}

func (b *Bastion) deleteSystemUser(username, ip string) error {
	systemUser, err := b.getSystemUserByName(username, ip)
	if err != nil {
		FsErrorf("deleteSystemUser.getSystemUserByName.err: %v", err)
		return err
	}
	if systemUser == nil {
		return nil
	}
	apiUrl, err := GetUrlWithParams(
		b.url,
		fmt.Sprintf("/api/v1/assets/system-users/%v/", systemUser.Id),
		nil,
	)
	if err != nil {
		FsErrorf("deleteSystemUser.GetUrlWithParams.err: %v", err)
		return err
	}
	body, _, err := DoNetworkRequest(http.MethodDelete, *apiUrl, "", b.getHeader(), nil)
	if err != nil {
		FsErrorf("deleteSystemUser.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}
	return nil
}

func (b *Bastion) getSystemUserByName(username, ip string) (*SystemUser, error) {
	apiUrl, err := GetUrlWithParams(
		b.url,
		"/api/v1/assets/system-users/",
		map[string]string{
			"name": fmt.Sprintf("%v_%v", username, ip),
		},
	)
	if err != nil {
		FsErrorf("getSystemUserByName.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	var systemUsers []SystemUser

	_, _, err = DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), &systemUsers)
	if err != nil {
		FsErrorf("getSystemUserByName.DoNetworkRequest.err: %v", err)
		return nil, err
	}

	if len(systemUsers) > 0 {
		return &systemUsers[0], nil
	}
	return nil, nil
}

// 针对某个授权策略，删除对于某个资源的授权
func (b *Bastion) RemoveAssetPermissionForAssetId(permission *AssetPermission, username string, ip string) error {
	asset, err := b.getAsset(ip)
	if err != nil {
		FsErrorf("RemoveAssetPermission.getAsset.err: %v", err)
		return err
	}
	updatedAssetIds := make([]string, 0)
	for _, item := range permission.Assets {
		if asset.Id == item {
			continue
		}
		updatedAssetIds = append(updatedAssetIds, item)
	}
	permission.Assets = updatedAssetIds

	apiUrl, err := GetUrlWithParams(
		b.url,
		fmt.Sprintf("/api/v1/perms/asset-permissions/%v/", permission.Id),
		nil,
	)
	if err != nil {
		FsErrorf("RemoveAssetPermission.GetUrlWithParams.err: %v", err)
		return err
	}

	body, _, err := DoNetworkRequest(http.MethodPut, *apiUrl, ToJsonString(permission), b.getHeader(), nil)
	if err != nil {
		FsErrorf("AttachUserAndAsset.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}
	err = b.deleteSystemUser(username, ip)
	if err != nil {
		FsErrorf("RemoveAssetPermission.deleteSystemUser.err: %v", err)
		return err
	}
	return nil
}

// 创建或者更新授权策略
func (b *Bastion) AttachUserAndAsset(user *User, newSystemUser *SystemUser, newAsset *Asset) error {
	var (
		actions = []string{
			"all",
			"connect",
			"upload_file",
			"download_file",
			"updownload",
			"clipboard_copy",
			"clipboard_paste",
			"clipboard_copy_paste",
		}
		method string
	)

	oldAssetPermission, err := b.GetAssetPermissions(user.UserName)
	if err != nil {
		FsErrorf("AttachUserAndAsset.GetAssetPermissions.err: %v", err)
		return err
	}

	var (
		resp   CreateAssetPermissionRequest
		apiUrl *string
	)
	if oldAssetPermission == nil {
		apiUrl, err = GetUrlWithParams(
			b.url,
			"/api/v1/perms/asset-permissions/",
			nil,
		)
		if err != nil {
			FsErrorf("AttachUserAndAsset.GetUrlWithParams.err: %v", err)
			return err
		}
		resp = CreateAssetPermissionRequest{
			Name:        user.Name,
			Actions:     actions,
			Assets:      []string{newAsset.Id},
			Users:       []string{user.Id},
			SystemUsers: []string{newSystemUser.Id},
			DateExpired: time.Now().AddDate(100, 0, 0).Format("2006/01/02 15:04:05 Z0700"),
			DateStart:   time.Now().Format("2006/01/02 15:04:05 Z0700"),
			IsActive:    true,
			IsExpired:   false,
			IsValid:     true,
			Nodes:       []string{},
			UserGroups:  []string{},
		}
		method = http.MethodPost
	} else {
		apiUrl, err = GetUrlWithParams(
			b.url,
			fmt.Sprintf("/api/v1/perms/asset-permissions/%v/", oldAssetPermission.Id),
			nil,
		)
		if err != nil {
			FsErrorf("AttachUserAndAsset.GetUrlWithParams.err: %v", err)
			return err
		}
		resp.Name = oldAssetPermission.Name
		resp.Actions = actions
		resp.Assets = AddEleIfNotExist(oldAssetPermission.Assets, newAsset.Id)
		resp.Users = oldAssetPermission.Users
		resp.SystemUsers = AddEleIfNotExist(oldAssetPermission.SystemUsers, newSystemUser.Id)
		resp.DateExpired = oldAssetPermission.DateExpired
		resp.DateStart = oldAssetPermission.DateStart
		resp.IsActive = oldAssetPermission.IsActive
		resp.IsExpired = oldAssetPermission.IsExpired
		resp.IsValid = oldAssetPermission.IsValid
		resp.Nodes = oldAssetPermission.Nodes
		resp.UserGroups = oldAssetPermission.UserGroups

		method = http.MethodPut
	}

	body, _, err := DoNetworkRequest(method, *apiUrl, ToJsonString(resp), b.getHeader(), nil)
	if err != nil {
		FsErrorf("AttachUserAndAsset.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}
	return nil
}

func (b *Bastion) GetAssetPermissions(username string) (*AssetPermission, error) {
	apiUrl, err := GetUrlWithParams(
		b.url,
		"/api/v1/perms/asset-permissions/",
		map[string]string{
			"name": username,
		},
	)
	if err != nil {
		FsErrorf("GetAssetPermissions.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	var r []AssetPermission

	body, _, err := DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), &r)
	if err != nil {
		FsErrorf("GetAssetPermissions.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return nil, err
	}

	if len(r) > 0 {
		return &r[0], nil
	}

	return nil, nil
}

type AttachIpToUserResponse struct {
	UserName           string `json:"user_name"`
	UserPassword       string `json:"user_password"`
	SystemUserPassword string `json:"system_user_password"`
}

// AttachIpToUser 关联用户和ip
func (b *Bastion) AttachIpToUser(username, email, ip string) (*AttachIpToUserResponse, error) {
	var (
		resp AttachIpToUserResponse
	)
	asset, err := b.getAsset(ip)
	if err != nil {
		FsErrorf(" AttachIpToUser.getAsset.err: %v", err)
		return nil, err
	}
	if asset == nil {
		errMsg := "资产查询或创建失败"
		return nil, errors.New(errMsg)
	}

	user, err := b.getUser(username)
	if err != nil {
		FsErrorf(" AttachIpToUser.getUser.err: %v", err)
		return nil, err
	}
	resp.UserName = username
	if user == nil {
		resp.UserPassword = GenCustomTypePassword(16, 0, 4, 4, 8)
		err = b.createUser(username, email, resp.UserPassword)
		if err != nil {
			FsErrorf(" AttachIpToUser.createUser.err: %v", err)
			return nil, err
		}
		user, err = b.getUser(username)
		if err != nil {
			FsErrorf(" AttachIpToUser.getUser.err: %v", err)
			return nil, err
		}
	}
	if user == nil {
		errMsg := "用户查询或创建失败"
		return nil, errors.New(errMsg)
	}

	resp.SystemUserPassword = GenCustomTypePassword(16, 0, 4, 4, 8)
	err = b.createSystemUser(username, ip, resp.SystemUserPassword)
	if err != nil {
		FsErrorf(" AttachIpToUser.createSystemUser.err: %v", err)
		return nil, err
	}
	systemUser, err := b.getSystemUserByName(username, ip)
	if err != nil {
		FsErrorf(" AttachIpToUser.getSystemUserByName.err: %v", err)
		return nil, err
	}

	err = b.AttachUserAndAsset(user, systemUser, asset)
	if err != nil {
		FsErrorf(" AttachIpToUser.AttachUserAndAsset.err: %v", err)
		return nil, err
	}

	return &resp, nil
}
