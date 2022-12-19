package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
)

func main() {
	commandDir := flag.String("command_dir", "", "命令所在目录, 必传")
	appName := flag.String("app_name", "", "app name, 非必传")
	appKey := flag.String("app_key", "", "app key, 非必传")

	flag.Parse()

	if *commandDir == "" {
		panic("-command_dir 不允许为空")
	}

	r := gin.Default()

	type RequestData struct {
		Command string `json:"command" binding:"required"`
		// 多个参数用分号连接
		Arguments string `json:"arguments"`
	}

	r.POST("/run", func(c *gin.Context) {
		var data RequestData
		if err := c.BindJSON(&data); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": err.Error()})
			return
		}
		args := strings.Split(data.Arguments, ";")

		absPath, err := filepath.Abs(*commandDir)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": err.Error()})
			return
		}

		if strings.Contains(data.Command, "/") {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": "不允许指定命令路径"})
			return
		}

		if _, err := os.Stat(path.Join(absPath, data.Command)); os.IsNotExist(err) {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": "在指定路径无法找到要执行的命令"})
			return
		}

		if *appName != "" && *appName != c.GetHeader("AppName") {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": "app name验证失败"})
			return
		}
		if *appKey != "" && *appKey != c.GetHeader("AppKey") {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": "app key验证失败"})
			return
		}

		cmd := exec.Command(data.Command, args...)
		output, err := cmd.CombinedOutput()
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"stat": 0, "info": fmt.Sprintf("执行命令失败, err: %v", err.Error())})
			return
		}

		c.JSON(http.StatusOK, gin.H{"stat": 1, "data": string(output)})
	})

	r.Run("0.0.0.0:8080")
}
