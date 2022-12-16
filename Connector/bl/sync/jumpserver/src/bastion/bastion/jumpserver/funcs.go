package jumpserver

import (
	"bl/src/logger"
	"bl/src/utils"
	"errors"
	"fmt"
	"net/http"
	"time"
)

// 检查用户是否存在
func (b *Bastion) getUser(username string) (*User, error) {
	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.Url,
		"/api/v1/users/users/",
		map[string]string{
			"username": username,
			"name":     username,
		},
	)
	if err != nil {
		logger.FsErrorf("checkIfUserExist.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	var r []User

	body, _, err := utils.DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), &r)
	if err != nil {
		logger.FsErrorf("checkIfUserExist.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return nil, err
	}
	if len(r) == 0 {
		return nil, nil
	}
	return &r[0], nil
}

func (b *Bastion) checkIfUserDuplicate(username, email string) (*bool, error) {
	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.Url,
		"/api/v1/users/users/",
		map[string]string{
			"username": username,
			"name":     username,
			"email":    email,
		},
	)
	if err != nil {
		logger.FsErrorf("checkIfUserDuplicate.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	var r []User

	body, _, err := utils.DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), &r)
	if err != nil {
		logger.FsErrorf("checkIfUserDuplicate.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return nil, err
	}
	exist := len(r) > 0
	return &exist, nil
}

// 创建用户
func (b *Bastion) createUser(username, email, password, phone string) error {
	exist, err := b.checkIfUserDuplicate(username, email)
	if err != nil {
		logger.FsErrorf("createUser.checkIfUserDuplicate.err: %v", err)
		return err
	}
	if *exist {
		errMsg := "用户名或邮箱已存在"
		return errors.New(errMsg)
	}

	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.Url,
		"/api/v1/users/users/",
		nil,
	)
	if err != nil {
		logger.FsErrorf("createUser.GetUrlWithParams.err: %v", err)
		return err
	}

	data := utils.ToJsonString(CreateUserRequest{
		Username:           username,
		Name:               username,
		Email:              email,
		MfaLevel:           0,
		NeedUpdatePassword: false,
		Password:           password,
		PasswordStrategy:   "custom",
		Phone:              phone,
		Source:             "local",
		SystemRoles:        []string{"00000000-0000-0000-0000-000000000003"},
	})

	body, _, err := utils.DoNetworkRequest(http.MethodPost, *apiUrl, data, b.getHeader(), nil)
	if err != nil {
		logger.FsErrorf("createUser.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}
	return nil
}

// 获取资产信息
func (b *Bastion) getAsset(ip string) (*Asset, error) {
	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.Url,
		"/api/v1/assets/assets/",
		map[string]string{
			"ip": ip,
		},
	)
	if err != nil {
		logger.FsErrorf("getAsset.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	var r []Asset

	body, _, err := utils.DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), &r)
	if err != nil {
		logger.FsErrorf("getAsset.DoNetworkRequest.err: %v, body = %v", err, string(body))
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
		logger.FsErrorf("createSystemUser.deleteSystemUser.err: %v", err)
		return err
	}

	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.Url,
		"/api/v1/assets/system-users/",
		nil,
	)
	if err != nil {
		logger.FsErrorf("createSystemUser.GetUrlWithParams.err: %v", err)
		return err
	}

	data := utils.ToJsonString(CreateSystemUserRequest{
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

	body, _, err := utils.DoNetworkRequest(http.MethodPost, *apiUrl, data, b.getHeader(), nil)
	if err != nil {
		logger.FsErrorf("createSystemUser.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}
	return nil
}

func (b *Bastion) deleteSystemUser(username, ip string) error {
	systemUser, err := b.getSystemUserByName(username, ip)
	if err != nil {
		logger.FsErrorf("deleteSystemUser.getSystemUserByName.err: %v", err)
		return err
	}
	if systemUser == nil {
		return nil
	}
	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.Url,
		fmt.Sprintf("/api/v1/assets/system-users/%v/", systemUser.Id),
		nil,
	)
	if err != nil {
		logger.FsErrorf("deleteSystemUser.GetUrlWithParams.err: %v", err)
		return err
	}
	body, _, err := utils.DoNetworkRequest(http.MethodDelete, *apiUrl, "", b.getHeader(), nil)
	if err != nil {
		logger.FsErrorf("deleteSystemUser.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}
	return nil
}

func (b *Bastion) getSystemUserByName(username, ip string) (*SystemUser, error) {
	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.Url,
		"/api/v1/assets/system-users/",
		map[string]string{
			"name": fmt.Sprintf("%v_%v", username, ip),
		},
	)
	if err != nil {
		logger.FsErrorf("getSystemUserByName.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	var systemUsers []SystemUser

	_, _, err = utils.DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), &systemUsers)
	if err != nil {
		logger.FsErrorf("getSystemUserByName.DoNetworkRequest.err: %v", err)
		return nil, err
	}

	if len(systemUsers) > 0 {
		return &systemUsers[0], nil
	}
	return nil, nil
}

// 创建或者更新授权策略
func (b *Bastion) upsertAssetPermission(user *User, newSystemUser *SystemUser, newAsset *Asset) error {
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

	oldAssetPermission, err := b.getAssetPermissions(user.UserName)
	if err != nil {
		logger.FsErrorf("upsertAssetPermission.getAssetPermissions.err: %v", err)
		return err
	}

	var (
		resp   CreateAssetPermissionRequest
		apiUrl *string
	)
	if oldAssetPermission == nil {
		apiUrl, err = utils.GetUrlWithParams(
			b.bastion.Url,
			"/api/v1/perms/asset-permissions/",
			nil,
		)
		if err != nil {
			logger.FsErrorf("upsertAssetPermission.GetUrlWithParams.err: %v", err)
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
		apiUrl, err = utils.GetUrlWithParams(
			b.bastion.Url,
			fmt.Sprintf("/api/v1/perms/asset-permissions/%v/", oldAssetPermission.Id),
			nil,
		)
		if err != nil {
			logger.FsErrorf("upsertAssetPermission.GetUrlWithParams.err: %v", err)
			return err
		}
		resp.Name = oldAssetPermission.Name
		resp.Actions = actions
		resp.Assets = utils.AddEleIfNotExist(oldAssetPermission.Assets, newAsset.Id)
		resp.Users = oldAssetPermission.Users
		resp.SystemUsers = utils.AddEleIfNotExist(oldAssetPermission.SystemUsers, newSystemUser.Id)
		resp.DateExpired = oldAssetPermission.DateExpired
		resp.DateStart = oldAssetPermission.DateStart
		resp.IsActive = oldAssetPermission.IsActive
		resp.IsExpired = oldAssetPermission.IsExpired
		resp.IsValid = oldAssetPermission.IsValid
		resp.Nodes = oldAssetPermission.Nodes
		resp.UserGroups = oldAssetPermission.UserGroups

		method = http.MethodPut
	}

	body, _, err := utils.DoNetworkRequest(method, *apiUrl, utils.ToJsonString(resp), b.getHeader(), nil)
	if err != nil {
		logger.FsErrorf("upsertAssetPermission.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}
	return nil
}

func (b *Bastion) getAssetPermissions(username string) (*AssetPermission, error) {
	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.Url,
		"/api/v1/perms/asset-permissions/",
		map[string]string{
			"name": username,
		},
	)
	if err != nil {
		logger.FsErrorf("getAssetPermissions.GetUrlWithParams.err: %v", err)
		return nil, err
	}

	var r []AssetPermission

	body, _, err := utils.DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), &r)
	if err != nil {
		logger.FsErrorf("getAssetPermissions.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return nil, err
	}

	if len(r) > 0 {
		return &r[0], nil
	}

	return nil, nil
}

// AttachIpToUserResponse 如果在执行AttachIpToUser时发现没有相关用户，最后返回下面这个结构
type AttachIpToUserResponse struct {
	UserName           string
	UserPassword       string
	SystemUserPassword string
}

// AttachIpToUser 关联用户和ip
//
// 如果用户在系统中不存在，返回创建的用户的名称和密码，否则返回空
func (b *Bastion) AttachIpToUser(username, email, phone, ip string) (*AttachIpToUserResponse, error) {
	var (
		resp AttachIpToUserResponse
	)
	asset, err := b.getAsset(ip)
	if err != nil {
		logger.FsErrorf(" AttachIpToUser.getAsset.err: %v", err)
		return nil, err
	}
	if asset == nil {
		errMsg := "资产查询或创建失败"
		return nil, errors.New(errMsg)
	}

	user, err := b.getUser(username)
	if err != nil {
		logger.FsErrorf(" AttachIpToUser.getUser.err: %v", err)
		return nil, err
	}
	resp.UserName = username
	if user == nil {
		resp.UserPassword = utils.GenCustomTypePassword(16, 4, 4, 4, 4)
		err = b.createUser(username, email, resp.UserPassword, phone)
		if err != nil {
			logger.FsErrorf(" AttachIpToUser.createUser.err: %v", err)
			return nil, err
		}
		user, err = b.getUser(username)
		if err != nil {
			logger.FsErrorf(" AttachIpToUser.getUser.err: %v", err)
			return nil, err
		}
	}
	if user == nil {
		errMsg := "用户查询或创建失败"
		return nil, errors.New(errMsg)
	}

	systemUser, err := b.getSystemUserByName(username, ip)
	if err != nil {
		logger.FsErrorf(" AttachIpToUser.getSystemUserByName.err: %v", err)
		return nil, err
	}
	if systemUser == nil {
		resp.SystemUserPassword = utils.GenCustomTypePassword(16, 4, 4, 4, 4)
		err = b.createSystemUser(username, ip, resp.SystemUserPassword)
		if err != nil {
			logger.FsErrorf(" AttachIpToUser.createSystemUser.err: %v", err)
			return nil, err
		}
		systemUser, err = b.getSystemUserByName(username, ip)
		if err != nil {
			logger.FsErrorf(" AttachIpToUser.getSystemUserByName.err: %v", err)
			return nil, err
		}
	}
	if user == nil {
		errMsg := "系统用户查询或创建失败"
		return nil, errors.New(errMsg)
	}

	err = b.upsertAssetPermission(user, systemUser, asset)
	if err != nil {
		logger.FsErrorf(" AttachIpToUser.upsertAssetPermission.err: %v", err)
		return nil, err
	}

	return &resp, nil
}
