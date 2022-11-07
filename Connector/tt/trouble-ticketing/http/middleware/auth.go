package middleware

import (
	"strings"

	"openc3.org/trouble-ticketing/funcs"
	"github.com/gin-gonic/gin"
)

func Auth() gin.HandlerFunc {

	var err error
	var user funcs.SSOUser

	// 忽略用户登陆认证的url 前缀
	skip := map[string]bool{
		"/public/ticket": true,
	}

	return func(c *gin.Context) {

		path := c.Request.URL.Path

		user, _, err = funcs.LoginRequire(c.Writer, c.Request)

		for url, _ := range skip {
			if strings.HasPrefix(path, url) {
				err = nil
				break
			}
		}

		if err != nil {
			c.JSON(200, gin.H{
				"code": 10000,
				"msg":  "not login",
			})
			c.Abort()
		}

		c.Set("oauser", user.Email)

	}

}
