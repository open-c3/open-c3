package src

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
)

/*
	功能说明：每隔 scanInterval 秒扫描 ScanDir 目录下每个文件(文件名不能重复，由用户自己负责更新文件)。

			文件名格式为:
				old_timestamp-md5
			文件内容格式为:
				user_script;arg1;arg2;arg3...

			脚本针对每个文件执行的功能为:
				if old_timestamp < now_timestamp {
					user_script arg1 arg2 arg3...
					delete_current_file
				}
*/

var (
	// 单位: 秒
	scanInterval time.Duration = 6
)

type RunCmdOnFile struct {
	CommandDir string
	ScanDir    string
}

func NewRunCmdOnFile(commandDir, scanDir string) *RunCmdOnFile {
	return &RunCmdOnFile{
		CommandDir: commandDir,
		ScanDir:    scanDir,
	}
}

func (r RunCmdOnFile) Run() error {
	for {
		filePathList, err := r.listFilesOfDir(r.ScanDir)
		if err != nil {
			return fmt.Errorf("Run.listFilesOfDir.error\n\t\t %v", err)
		}
		for _, filePath := range filePathList {
			base := filepath.Base(filePath)
			ok, err := r.ifOkRunCmd(strings.Split(base, "-")[0])
			if err != nil {
				return fmt.Errorf("Run.ifOkRunCmd.err: %v", err)
			}
			if !ok {
				continue
			}
			err = r.runCmdOnFile(filePath)
			if err != nil {
				return fmt.Errorf("Run.runCmdOnFile.error\n\t\t %v", err)
			}
		}
		logrus.Info("完成扫描!")
		time.Sleep(scanInterval * time.Second)
	}
}

func (r RunCmdOnFile) runCmdOnFile(filePath string) error {
	data, err := r.readFileFirstLine(filePath)
	if err != nil {
		return fmt.Errorf("runCmd.readFileFirstLine.err: %v", err)
	}
	if *data == "" {
		return nil
	}

	var (
		args    []string
		userCmd string
	)
	parts := strings.Split(*data, ";")
	if len(parts) <= 0 {
		return nil
	} else if len(parts) == 1 {
		userCmd = parts[0]
	} else {
		userCmd = parts[0]
		args = parts[1:]
	}

	cmd := exec.Command(filepath.Join(r.CommandDir, userCmd), args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	// 运行命令
	err = cmd.Run()
	if err != nil {
		return fmt.Errorf("runCmd.Command.err: %v", err)
	}

	err = os.Remove(filePath)
	if err != nil {
		return fmt.Errorf("runCmd.Remove.err: %v", err)
	}

	logrus.Infof("成功执行脚本: %v, 参数为: %v\n", userCmd, strings.Join(args, " "))

	return nil
}

func (r RunCmdOnFile) ifOkRunCmd(timestampStr string) (bool, error) {
	timestamp, err := strconv.ParseInt(timestampStr, 10, 64)
	if err != nil {
		return false, fmt.Errorf("ifOkRunCmd.ParseInt.err: %v", err)
	}
	if timestamp > time.Now().Unix() {
		return false, nil
	}
	return true, nil
}

func (r RunCmdOnFile) listFilesOfDir(rootDir string) ([]string, error) {
	dir, err := os.Open(rootDir)
	if err != nil {
		return nil, fmt.Errorf("listFilesOfDir.Open.err: %v", err)
	}
	defer dir.Close()

	files, err := dir.Readdir(-1)
	if err != nil {
		return nil, fmt.Errorf("listFilesOfDir.Readdir.err: %v", err)
	}

	result := make([]string, 0)
	for _, file := range files {
		absPath, err := filepath.Abs(filepath.Join(rootDir, file.Name()))
		if err != nil {
			return nil, fmt.Errorf("listFilesOfDir.Abs.err: %v", err)
		}
		result = append(result, absPath)
	}
	return result, nil
}

func (r RunCmdOnFile) readFileFirstLine(filePath string) (*string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("readFileFirstLine.Open.err: %v", err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	if scanner.Scan() {
		firstLine := scanner.Text()
		return &firstLine, nil
	}
	if err = scanner.Err(); err != nil {
		return nil, fmt.Errorf("readFileFirstLine.scanner.err: %v", err)
	}
	return nil, errors.New("读取文件失败")
}
