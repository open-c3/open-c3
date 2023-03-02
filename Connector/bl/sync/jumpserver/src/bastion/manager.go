package bastion

import (
	"bl/src/logger"
	"bl/src/model"
	"fmt"
	"os/exec"
	"strings"
)

func SyncMachines(user, pass, url, appName, appKey string) {
	syncBastion := NewBastion(
		model.Bastion{
			User: user,
			Pass: pass,
			Url:  url,
		},
	)

	err := syncBastion.SetToken()
	if err != nil {
		logger.FsErrorf("SyncMachine.SetToken.err: %v", err)
		return
	}
	err = Helper(syncBastion, appName, appKey)
	if err != nil {
		logger.FsErrorf("SyncMachine.Helper.err: %v", err)
		return
	}
}

func getSysCtlValue(variable string) string {
	cmd := exec.Command("c3mc-sys-ctl", variable)
	stdout, err := cmd.Output()
	if err != nil {
		fmt.Println(err.Error())
		return ""
	}
	return strings.TrimSpace(string(stdout))
}
