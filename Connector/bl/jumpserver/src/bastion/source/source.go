package source

import (
	"bl/src/logger"
	"bl/src/model"
	"bl/src/utils"
	"net/http"
	"os"
	"strings"
)

type C3MachineInfoList struct{}

func (c C3MachineInfoList) GetMachineInfoList() ([]model.MachineInfo, error) {
	appkey := strings.TrimSpace(os.Getenv("OPEN_C3_RANDOM"))
	if appkey == "" {
		return nil, nil
	}

	header := map[string]string{
		"Content-Type": "application/json",
		"appname":      "job",
		"appkey":       appkey,
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
