package funcs

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"
)

func SendEmail(content, subject string, receivers []string) error {
	cmd := exec.Command("c3mc-base-sendmail", strings.Join(receivers, " "), "--subject", subject)
	cmd.Stdin = strings.NewReader(content)

	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		PrintlnLog(fmt.Sprintf("SendEmail.Run.err: %v", stderr.String()))
		return err
	}
	return nil
}
