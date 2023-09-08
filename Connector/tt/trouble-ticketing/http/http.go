package http

import (
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"openc3.org/trouble-ticketing/config"
	"openc3.org/trouble-ticketing/http/cookie"
	"openc3.org/trouble-ticketing/http/handler"
	"openc3.org/trouble-ticketing/http/middleware"
	"openc3.org/trouble-ticketing/http/routers"
	"openc3.org/trouble-ticketing/orm"

	_ "openc3.org/trouble-ticketing/docs"

	"github.com/gin-contrib/pprof"
	"github.com/gin-gonic/gin"
)

func Start() {
	cookie.Init()
	orm.InitMysql()

	// cron
	go handler.CronCloseTicket()
	go handler.CronSLACheck()

	httpStart()
}

func httpStart() {

	if !config.Config().Debug {
		gin.SetMode(gin.ReleaseMode)
	}
	g := gin.Default()
	pprof.Register(g)

	g.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	g.Use(middleware.Auth())
	routers.ConfigRouter(&g.RouterGroup)
	g.Run(config.Config().HTTP.Listen)

}
