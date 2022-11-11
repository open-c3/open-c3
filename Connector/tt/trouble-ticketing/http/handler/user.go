package handler

import (
	"fmt"
	"net/http"
	"openc3.org/trouble-ticketing/funcs"

	"github.com/gin-gonic/gin"
)

func GetUserInfo(c *gin.Context) {
	user := c.Query("user")
	if user == "" {
		c.JSON(http.StatusOK, status_400("用户名不允许为空"))
		return
	}

	userInfo, err := funcs.GetUserInfo(user)
	if err != nil {
		funcs.PrintlnLog(fmt.Sprintf("GetUserInfo.err: %v", err))
		c.JSON(http.StatusOK, status_400("获取用户信息出错"))
		return
	}
	c.JSON(http.StatusOK, status_200(userInfo))
}
