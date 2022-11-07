package handler

import (
	"net/http"

	"openc3.org/trouble-ticketing/config"

	"github.com/gin-gonic/gin"
)

//
func SelfVersion(c *gin.Context) {
	version := config.VERSION
	c.JSON(http.StatusOK, status_200(version))
}
