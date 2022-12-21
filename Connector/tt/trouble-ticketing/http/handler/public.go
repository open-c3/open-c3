package handler

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"openc3.org/trouble-ticketing/config"
	"openc3.org/trouble-ticketing/orm"
)

// 第三方系统添加事件
func PublicPostTicket(c *gin.Context) {
	type reqT struct {
		Title     string `json:"title" binding:"required"`
		Content   string `json:"content" binding:"required"`
		EmailList string `json:"email_list"`

		Impact int64 `json:"impact"`
		C      int64 `json:"c"`
		T      int64 `json:"t"`
		I      int64 `json:"i"`

		SubmitUser string `json:"submit_user"`
		ApplyUser  string `json:"apply_user"`
	}

	var req reqT

	err := c.BindJSON(&req)
	if err != nil {
		c.JSON(http.StatusOK, status_400_v2(err.Error()))
		return
	}
	var (
		obj            ticket
		defaultGroupId int64
		defaultUserId  int64
		found          bool
	)
	for _, workflowConfig := range config.Config().Workflow {
		for _, keyword := range workflowConfig.Keyword {
			if strings.Contains(req.Title, keyword) {
				defaultGroupId = workflowConfig.WorkGroupId
				defaultUserId = workflowConfig.GroupUserId
				found = true
				break
			}
		}
	}
	if !found {
		c.JSON(http.StatusOK, status_400_v2("没有找到默认的组和处理用户, 工单名称: "+req.Title))
		return
	}

	if strings.TrimSpace(req.ApplyUser) == "" {
		c.JSON(http.StatusOK, status_400_v2("apply user reqiured"))
		return
	}

	obj.ApplyUser = req.ApplyUser
	obj.Impact = req.Impact
	obj.Category = req.C
	obj.Type = req.T
	obj.Item = req.I
	obj.Workgroup = defaultGroupId
	obj.GroupUser = defaultUserId
	obj.Title = req.Title
	obj.Content = req.Content
	obj.EmailList = req.EmailList
	obj.SubmitUser = req.SubmitUser
	obj.ApplyUser = req.ApplyUser

	err = orm.Db.Create(&obj).Error
	if err != nil {
		c.JSON(http.StatusOK, status_400_v2(err.Error()))
		return
	}
	c.JSON(http.StatusOK, status_200_v2(obj.No))
}

// 获取某个事件状态
func PublicGetTicketStatus(c *gin.Context) {

	type ticket struct {
		ID     int64  `json:"id"`
		No     string `json:"no"`
		Status string `json:"status"`
	}

	id := c.Param("id")
	var obj ticket
	var count int64
	if len(id) == 12 {
		orm.Db.Table("openc3_tt_ticket").Where("no = ?", id).Select("id, no, status").First(&obj).Count(&count)
	} else {
		orm.Db.Table("openc3_tt_ticket").Where("id = ?", id).Select("id, no, status").First(&obj).Count(&count)
	}

	if count == 0 {
		c.JSON(http.StatusOK, status_404(fmt.Sprintf("%s not found", id)))
		return
	}

	// return
	c.JSON(http.StatusOK, status_200(obj))
}

// 获取事件基础信息　批量
func PublicGetTicketInfo(c *gin.Context) {

	type request struct {
		No string `json:"no" binding:"required"` // 逗号分隔多个事件no/id
	}

	type ticket struct {
		ID           int64  `json:"id"`
		No           string `json:"no"`
		Status       string `json:"status"`
		ResponseCost int64  `json:"response_cost"`
		ResolveCost  int64  `json:"resolve_cost"`
	}

	obj := make([]ticket, 0)
	var req request

	if c.BindJSON(&req) == nil {

		no_arr := strings.Split(req.No, ",")

		if err := orm.Db.Table("openc3_tt_ticket").Where("id in (?)", no_arr).Or("no in (?)", no_arr).Select("id, no, response_cost, resolve_cost, status").Find(&obj).Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
		} else {
			c.JSON(http.StatusOK, status_200(obj))
		}

	}

}
