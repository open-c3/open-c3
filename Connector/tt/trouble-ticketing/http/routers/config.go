package routers

import (
	"openc3.org/trouble-ticketing/http/handler"
	"openc3.org/trouble-ticketing/http/middleware"
	"github.com/gin-gonic/gin"
)

func ConfigRouter(r *gin.RouterGroup) {
	ticket_route(r)
	base_route(r.Group("/base"))
	search_route(r.Group("/search"))
	common_route(r.Group("/common"))
	report_route(r.Group("/report")) // 报表类接口
	public_route(r.Group("/public")) // 公共接口，第三方系统调用
	self_route(r.Group("/self"))     // TT自身
}

func base_route(r *gin.RouterGroup) {

	adminRequired := r.Group("/")
	adminRequired.Use(middleware.AdminRequired())
	{
		adminRequired.POST("/impact", handler.PostBaseImpact)
		adminRequired.PUT("/impact/:id", handler.PutBaseImpact)
		adminRequired.DELETE("/impact/:id", handler.DeleteBaseImpact)

		adminRequired.POST("/category", handler.PostBaseCategory)
		adminRequired.PUT("/category/:id", handler.PutBaseCategory)
		adminRequired.DELETE("/category/:id", handler.DeleteBaseCategory)

		adminRequired.POST("/type", handler.PostBaseType)
		adminRequired.PUT("/type/:id", handler.PutBaseType)
		adminRequired.DELETE("/type/:id", handler.DeleteBaseType)

		adminRequired.POST("/item", handler.PostBaseItem)
		adminRequired.PUT("/item/:id", handler.PutBaseItem)
		adminRequired.DELETE("/item/:id", handler.DeleteBaseItem)

		adminRequired.POST("/group", handler.PostBaseGroup)
		adminRequired.DELETE("/group/:id", handler.DeleteBaseGroup)

		adminRequired.POST("/item_group_map", handler.PostBaseItemGroupMap)
		adminRequired.PUT("/item_group_map/:id", handler.PutBaseItemGroupMap)
		adminRequired.DELETE("/item_group_map/:id", handler.DeleteBaseItemGroupMap)

		adminRequired.POST("/email_templates", handler.PostBaseEmailTemplates)
		adminRequired.PUT("/email_templates/:id", handler.PutBaseEmailTemplates)
		adminRequired.DELETE("/email_templates/:id", handler.DeleteBaseEmailTemplates)
	}

	r.GET("/impact/*id", handler.GetBaseImpact)
	r.GET("/category/*id", handler.GetBaseCategory)
	r.GET("/type/*id", handler.GetBaseType)
	r.GET("/item/*id", handler.GetBaseItem)

	r.GET("/group/*id", handler.GetBaseGroup)
	r.PUT("/group/:id", handler.PutBaseGroup)

	r.GET("/item_group_map/*id", handler.GetBaseItemGroupMap)

	r.GET("/group_user/*id", handler.GetBaseGroupUser)
	r.POST("/group_user", handler.PostBaseGroupUser)
	r.PUT("/group_user/:id", handler.PutBaseGroupUser)
	r.DELETE("/group_user/:id", handler.DeleteBaseGroupUser)

	r.GET("/email_templates/*id", handler.GetBaseEmailTemplates)

	r.GET("/all", handler.GetBaseAll)
	r.GET("/cti_tree_map", handler.GetCITtreeMap)
	r.GET("/group_item_user_rel", handler.GetGroupItemUserRel)
}

func ticket_route(r *gin.RouterGroup) {

	// ticket
	r.GET("/ticket/:id", handler.GetTicket)
	r.POST("/ticket", handler.PostTicket)
	r.PUT("/ticket/:id", handler.PutTicket)

	// attachment
	r.GET("/attachment/list/:ticketid", handler.GetAttachment)
	r.GET("/attachment/download/:ticketid/:uuid", handler.DownloadAttachment)
	r.POST("/attachment/upload/:ticketid", handler.PostAttachment)
	r.DELETE("/attachment/:ticketid/:uuid", handler.DeleteAttachment)

	// status flow
	r.GET("/status_flow/:ticketid", handler.GetTicketStatusFlowLog)
}

func common_route(r *gin.RouterGroup) {

	// replylog
	r.GET("/replylog/:ticketid", handler.GetCommonReplyLog)
	r.POST("/replylog", handler.PostCommonReplyLog)

	// worklog
	r.GET("/worklog/:ticketid", handler.GetCommonWorkLog)
	r.POST("/worklog", handler.PostCommonWorkLog)

	// syslog
	r.GET("/syslog/:ticketid", handler.GetCommonSysLog)

	// i18n
	r.GET("/i18n", handler.GetCommonI18n)
	r.PUT("/i18n/:id", middleware.AdminRequired(), handler.PutCommonI18n)

}

func search_route(r *gin.RouterGroup) {

	index := r.Group("index")
	{
		index.GET("/level12", handler.SearchLevel12)
		index.GET("/selfsubmit", handler.SearchSelfsubmit)
		index.GET("/assignme", handler.SearchAssignMe)
		index.GET("/emaillistme", handler.SearchEmaillistMe)
		index.GET("/menulist", handler.SearchMenuList)
		index.GET("/myticket", handler.SearchMyticket)
	}

	list := r.Group("list")
	{
		list.POST("/", handler.SearchList)
		list.POST("/open_ticket_for_user", handler.SearchOpenTicketForUser)
	}

	r.POST("/export", handler.ExportTickets)

}

func report_route(r *gin.RouterGroup) {
	r.POST("/kanban", handler.ReportKanban)
}

func public_route(r *gin.RouterGroup) {
	r.POST("/ticket", handler.PublicPostTicket)                // 第三方系统添加事件
	r.GET("/ticket/status/:id", handler.PublicGetTicketStatus) // 获取事件状态
	r.POST("/ticket/info", handler.PublicGetTicketInfo)        // 获取事件基础信息
}

func self_route(r *gin.RouterGroup) {
	r.GET("/version", handler.SelfVersion)
}
