package jumpserver

import (
	"bl/src/bastion/bastion"
	"bl/src/logger"
	"bl/src/model"
	"bl/src/utils"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
)

type Bastion struct {
	token   string
	bastion model.Bastion
}

// NewBastion -.
func NewBastion(bastion model.Bastion) *Bastion {
	return &Bastion{
		bastion: bastion,
	}
}

func (b *Bastion) SetToken() error {
	user := b.bastion.AuthUser
	password := b.bastion.AuthPass

	apiUrl, err := utils.GetUrlWithParams(b.bastion.BaseUrl, "/api/v1/authentication/auth/", nil)
	if err != nil {
		logger.FsErrorf("SetToken.GetUrlWithParams.err: %v", err)
		return err
	}

	postData := utils.ToJsonString(AuthenticateBody{
		Username: user,
		Password: password,
	})

	header := map[string]string{
		"Content-Type": "application/json",
	}

	var resp AuthenticateResponse
	body, _, err := utils.DoNetworkRequest(http.MethodPost, *apiUrl, postData, header, &resp)
	if err != nil {
		logger.FsErrorf("SetToken.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}
	if len(body) > 0 && (strings.Contains(string(body), "password_failed") || strings.Contains(string(body), "block_login")) {
		type errResp struct {
			Err error  `json:"err"`
			Msg string `json:"msg"`
		}
		var er errResp
		err = json.Unmarshal(body, &er)
		if err != nil {

			logger.FsErrorf("SetToken.Unmarshal.err: %v, body = %v", err, string(body))
			return err
		}
		return errors.New(er.Msg)
	}
	b.token = resp.Token

	return nil
}

func (b *Bastion) GetManufacturer() bastion.Manufacturer {
	return b.bastion.Manufacturer
}

func (b *Bastion) GetFilterVpcKeywords() []string {
	return b.bastion.FilterVpcKeyWords
}

func (b *Bastion) GetBastionData() model.Bastion {
	return b.bastion
}

func (b *Bastion) getHeader() map[string]string {
	return map[string]string{
		"Authorization": fmt.Sprintf("Bearer %v", b.token),
		"Content-Type":  "application/json",
	}
}

func (b *Bastion) GetAssetMap(localMachines []model.MachineInfo) (map[interface{}]model.MachineInfo, map[interface{}]interface{}, error) {
	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.BaseUrl,
		"/api/v1/assets/assets/",
		nil,
	)
	if err != nil {
		logger.FsErrorf("GetAssetMap.GetUrlWithParams.err: %v", err)
		return nil, nil, err
	}

	assets := make([]Asset, 0)

	body, _, err := utils.DoNetworkRequest(http.MethodGet, *apiUrl, "", b.getHeader(), assets)
	if err != nil {
		logger.FsErrorf("GetAssetMap.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return nil, nil, err
	}

	var (
		mBastion = make(map[interface{}]interface{})
		mLocal   = make(map[interface{}]model.MachineInfo)
	)
	for _, item := range assets {
		mBastion[item.Ip] = item
	}

	for _, item := range localMachines {
		mLocal[item.IP] = item
	}

	return mLocal, mBastion, nil
}

func (b *Bastion) CompareMachineInfoAndAsset(machineInfo model.MachineInfo, asset interface{}) (*bool, error) {
	assetInfo, ok := asset.(Asset)
	if !ok {
		errMsg := "CompareMachineInfoAndAsset.类型判断错误"
		logger.FsError(errMsg)
		return nil, errors.New(errMsg)
	}
	same := false

	if assetInfo.HostName == machineInfo.HostName &&
		assetInfo.Ip == machineInfo.IP {
		same = true
	}

	return &same, nil
}

func (b *Bastion) DeleteAsset(asset interface{}) error {
	assetInfo := asset.(Asset)
	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.BaseUrl,
		fmt.Sprintf("/api/v1/assets/assets/%v/", assetInfo.Id),
		nil,
	)
	if err != nil {
		logger.FsErrorf("DeleteAsset.GetUrlWithParams.err: %v", err)
		return err
	}
	body, _, err := utils.DoNetworkRequest(http.MethodDelete, *apiUrl, "", b.getHeader(), nil)
	if err != nil {
		logger.FsErrorf("DeleteAsset.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}

	return nil
}

func (b *Bastion) CreateOrUpdateAsset(machineInfo model.MachineInfo) error {
	apiUrl, err := utils.GetUrlWithParams(
		b.bastion.BaseUrl,
		"/api/v1/assets/assets/",
		nil,
	)
	if err != nil {
		logger.FsErrorf("CreateAsset.GetUrlWithParams.err: %v", err)
		return err
	}

	id, err := utils.GetUUID()
	if err != nil {
		return err
	}

	data := utils.ToJsonString(CreateAssetRequest{
		// jumpserver 要求uuid是这种格式 a1856c5a-1789-11ed-bddf-bee271d8d5b5。
		// 但是数据库里记录的uuid和资源的实例id都不是这种格式
		Id:       *id,
		HostName: machineInfo.HostName,
		Ip:       machineInfo.IP,
		Platform: machineInfo.OS,
		Comment:  fmt.Sprintf("[%v]", machineInfo.InstanceId),
	})

	body, _, err := utils.DoNetworkRequest(http.MethodPost, *apiUrl, data, b.getHeader(), nil)
	if err != nil {
		logger.FsErrorf("CreateAsset.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return err
	}

	return nil
}
