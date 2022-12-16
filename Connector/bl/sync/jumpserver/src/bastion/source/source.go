package source

import (
	"bl/src/logger"
	"bl/src/model"
	"bl/src/utils"
	"net/http"
)

type C3MachineInfoList struct{}

func (c C3MachineInfoList) GetMachineInfoList(appName, appKey string) ([]model.MachineInfo, error) {
	header := map[string]string{
		"Content-Type": "application/json",
		"appname":      appName,
		"appkey":       appKey,
	}

	url := "http://localhost:88/api/ci/v2/c3mc/jumpserver"

	type resp struct {
		Data []model.MachineInfo `json:"data"`
	}

	var r resp
	body, _, err := utils.DoNetworkRequest(http.MethodGet, url, "", header, &r)
	if err != nil {
		logger.FsErrorf("GetMachineInfoList.DoNetworkRequest.err: %v, body = %v", err, string(body))
		return nil, err
	}
	return r.Data, nil
}
