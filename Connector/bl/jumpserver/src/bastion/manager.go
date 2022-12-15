package bastion

import (
	"bl/src/logger"
	"bl/src/model"
	"fmt"
	"os/exec"
	"strings"
)

func SyncMachines(user, pass, url string) {
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
	err = Helper(syncBastion)
	if err != nil {
		logger.FsErrorf("SyncMachine.Helper.err: %v", err)
		return
	}
}

func getBlAccountAndPass() (string, string, string, string) {
	blMode := getSysCtlValue("sys.bl.mode")
	if blMode == "none" || blMode == "" {
		return "", "", "", ""
	}
	user := getSysCtlValue(fmt.Sprintf("sys.bl.sync.%s.admin.user", blMode))
	pass := getSysCtlValue(fmt.Sprintf("sys.bl.sync.%s.admin.pass", blMode))
	url := getSysCtlValue(fmt.Sprintf("sys.bl.sync.%s.url", blMode))

	return user, pass, url, blMode
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
