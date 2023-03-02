package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"proxy/src"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

func main() {
	logrus.SetFormatter(&logrus.TextFormatter{
		FullTimestamp: true,
	})

	var (
		defaultScanDir = "scan_dir"
	)

	commandDir := flag.String("command_dir", "", "命令所在目录，使用绝对路径, 必传")
	appName := flag.String("app_name", "", "app name, 非必传")
	appKey := flag.String("app_key", "", "app key, 非必传")
	scanDir := flag.String("scan_dir", "", "定时任务扫描的绝对路径, 如果不指定, 则在当前路径创建scan_dir目录")
	portStr := flag.String("port", "", "监听端口, 必传")

	flag.Parse()

	if *commandDir == "" {
		panic("-command_dir 不允许为空")
	}
	if *portStr == "" {
		panic("-port 不允许为空")
	}

	if *scanDir == "" {
		dir, err := createDir(defaultScanDir)
		if err != nil {
			log.Fatalf("createDir.err: %v", err)
		}
		scanDir = dir
	}
	port, err := strconv.Atoi(*portStr)
	if err != nil {
		panic("-port 不允许为空")
	}

	r := gin.Default()

	type RequestData struct {
		Command   string `json:"command" binding:"required"`
		Arguments string `json:"arguments"`
	}

	r.POST("/run", func(c *gin.Context) {
		var data RequestData
		if err := c.BindJSON(&data); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": err.Error()})
			return
		}

		absPath, err := filepath.Abs(*commandDir)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": err.Error()})
			return
		}

		if strings.Contains(data.Command, "/") {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": "不允许指定命令路径"})
			return
		}

		if _, err = os.Stat(path.Join(absPath, data.Command)); os.IsNotExist(err) {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": "在指定路径无法找到要执行的命令"})
			return
		}


		if *appName != "" && *appName != c.GetHeader("app_name") {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": "app name验证失败"})
			return
		}
		if *appKey != "" && *appKey != c.GetHeader("app_key") {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": "app key验证失败"})
			return
		}

		var args map[string]interface{}

		err = json.Unmarshal([]byte(data.Arguments), &args)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": "命令参数提取失败"})
			return
		}
		argsStr := make([]string, 0)
		for key, value := range args {
			argsStr = append(argsStr, fmt.Sprintf("-%v", key))
			argsStr = append(argsStr, fmt.Sprintf("%v", value))
		}

		if strings.Contains(data.Arguments, "add_type") {
			argsStr = append(argsStr, "-scan_dir")
			argsStr = append(argsStr, fmt.Sprintf("%v", *scanDir))
		}

		cmdStr := filepath.Join(*commandDir, data.Command)
		log.Println("cmdStr = ", cmdStr)
		log.Println("args = ", argsStr)

		cmd := exec.Command(cmdStr, argsStr...)
		output, err := cmd.CombinedOutput()
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": fmt.Sprintf("执行命令失败, err: %v", err.Error())})
			return
		}

		c.JSON(http.StatusOK, gin.H{"stat": 1, "data": strings.TrimSpace(string(output))})
	})

	go func() {
		r := src.NewRunCmdOnFile(*commandDir, *scanDir)
		err := r.Run()
		if err != nil {
			log.Println(err)
		}
	}()

	err = r.Run(fmt.Sprintf("0.0.0.0:%d", port))
	if err != nil {
		log.Fatal(err)
	}
}

func createDir(dirName string) (*string, error) {
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
