package middleware

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
)

func Logger() gin.HandlerFunc {

	return func(c *gin.Context) {

		t := time.Now()

		c.Next()

		latency := time.Since(t)

		fmt.Println(time.Now().Format("2006-01-02 15:04:05"), c.Request.Method, c.Request.URL.Path, c.ClientIP(), c.Writer.Size(), c.Writer.Status(), latency)
	}

}
