package src

import (
	"crypto/md5"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type UpsertSudo struct {
	SudoFileDir string
}

func NewUpsertSudo(sudoFileDir string) *UpsertSudo {
	return &UpsertSudo{
		SudoFileDir: sudoFileDir,
	}
}

func (u UpsertSudo) Upsert(username, ip string, sudoHours int) error {
	dirPath, err := u.createDir(u.SudoFileDir)
	if err != nil {
		return fmt.Errorf("Upsert.createDirIfNotExist.error\n\t\t %v", err)
	}
	data := []byte(fmt.Sprintf("%v;%v", username, ip))
	hash := fmt.Sprintf("%x", md5.Sum(data))

	filePathList, err := u.listFilesOfDir(*dirPath)
	if err != nil {
		return fmt.Errorf("Upsert.listFilesOfDir.error\n\t\t %v", err)
	}
	for _, filePath := range filePathList {
		if strings.Contains(filePath, hash) {
			err = os.Remove(filePath)
			if err != nil {
				return fmt.Errorf("Upsert.Remove.error\n\t\t %v", err)
			}
		}
	}

	timestamp := time.Now().Unix() + int64(sudoHours*3600)
	filePath := filepath.Join(*dirPath, fmt.Sprintf("%v-%v", timestamp, hash))
	content := []byte(fmt.Sprintf("del_just_sudo_privilege;%v;%v", username, ip))

	err = os.WriteFile(filePath, content, 0644)
	if err != nil {
		return fmt.Errorf("Upsert.WriteFile.error\n\t\t %v", err)
	}
	return nil
}

func (u UpsertSudo) listFilesOfDir(rootDir string) ([]string, error) {
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

func (u UpsertSudo) ifPathExist(path string) (bool, error) {
	if _, err := os.Stat(path); err == nil {
		return true, nil
	} else if os.IsNotExist(err) {
		return false, nil
	} else {
		return false, err
	}
}

func (u UpsertSudo) createDir(dirName string) (*string, error) {
	absPath, err := filepath.Abs(dirName)
	if err != nil {
		return nil, err
	}
	if _, err := os.Stat(absPath); os.IsNotExist(err) {
		err = os.Mkdir(absPath, 0755)
		if err != nil {
			return nil, err
		}
	}
	return &absPath, nil
}
