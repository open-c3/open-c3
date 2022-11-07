package middleware

import (
	"openc3.org/trouble-ticketing/funcs"
	"github.com/gin-gonic/gin"
)

// tt_admin role
func AdminRequired() gin.HandlerFunc {

	return func(c *gin.Context) {
		if !funcs.CheckPmsRole(c.Request, "tt_admin") {
			c.JSON(200, gin.H{
				"code": 403,
				"msg":  "forbidden",
				"data": "admin required",
			})
			c.Abort()
		}
	}

}
