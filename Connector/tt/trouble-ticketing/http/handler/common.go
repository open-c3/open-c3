package handler

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"

	"github.com/gin-gonic/gin"
)

// -------- reply log --------

// 获取某个ticket的所有replylog
func GetCommonReplyLog(c *gin.Context) {
	ticketid := c.Param("ticketid")
	obj := make([]model.CommonReplyLog, 0)
	orm.Db.Table("openc3_tt_common_reply_log").Where("ticket_id = ?", ticketid).Order("id desc").Find(&obj)
	c.JSON(http.StatusOK, status_200(obj))
}

// add reply log
func PostCommonReplyLog(c *gin.Context) {
	var obj model.CommonReplyLog
	if c.BindJSON(&obj) == nil {
		oauser, _ := c.Get("oauser")
		obj.OperUser = oauser.(string)
		if len(obj.Content) > 0 {
			// check ticketid exist
			var ticket model.Ticket
			if orm.Db.Where("id = ?", obj.TicketId).First(&ticket).RecordNotFound() {
				c.JSON(http.StatusOK, status_400(fmt.Sprintf("Ticket TT%010s not exist.", obj.TicketId)))
				return
			}
			// add reply log
			db := orm.Db.Create(&obj)
			if err := db.Error; err != nil {
				c.JSON(http.StatusOK, status_400(err.Error()))
				return
			}
			affected := db.RowsAffected
			if affected > 0 {
				// check response time
				if ticket.ResponseTime.IsZero() {
					var group model.BaseGroupUser
					// check priv
					if !orm.Db.Where("email = ? and group_id = ?", oauser.(string), ticket.Workgroup).First(&group).RecordNotFound() {
						var workgroup model.BaseGroup
						orm.Db.Where("id = ?", ticket.Workgroup).First(&workgroup)
						ticket.ResponseTime = time.Now()
						//ticket.ResponseCost = CalWorktimeCost(ticket.CreatedAt, time.Now(), workgroup)
						orm.Db.Table("openc3_tt_ticket").Where("id = ?", ticket.ID).Update(ticket)
					}
				}
				// mail
				go sendmail(oauser.(string), "ticket_add_reply", ticket.ID, nil)
			}
			c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
		}
	}
}

// -------- work log --------

// 获取某个ticket的所有worklog
func GetCommonWorkLog(c *gin.Context) {
	ticketid := c.Param("ticketid")
	obj := make([]model.CommonWorkLog, 0)
	orm.Db.Table("openc3_tt_common_work_log").Where("ticket_id = ?", ticketid).Order("id desc").Find(&obj)
	c.JSON(http.StatusOK, status_200(obj))
}

// add work log
func PostCommonWorkLog(c *gin.Context) {
	var obj model.CommonWorkLog
	if c.BindJSON(&obj) == nil {
		oauser, _ := c.Get("oauser")
		obj.OperUser = oauser.(string)
		if len(obj.Content) > 0 {
			// check ticketid exist
			var ticket model.Ticket
			if orm.Db.Where("id = ?", obj.TicketId).First(&ticket).RecordNotFound() {
				c.JSON(http.StatusOK, status_400(fmt.Sprintf("Ticket TT%010s not exist.", obj.TicketId)))
				return
			}
			// add work log
			db := orm.Db.Create(&obj)
			if err := db.Error; err != nil {
				c.JSON(http.StatusOK, status_400(err.Error()))
				return
			}
			affected := db.RowsAffected
			if affected > 0 {
				// check response time
				if ticket.ResponseTime.IsZero() {
					var group model.BaseGroupUser
					// check priv
					if !orm.Db.Where("email = ? and group_id = ?", oauser.(string), ticket.Workgroup).First(&group).RecordNotFound() {
						var workgroup model.BaseGroup
						orm.Db.Where("id = ?", ticket.Workgroup).First(&workgroup)
						ticket.ResponseTime = time.Now()
						//ticket.ResponseCost = CalWorktimeCost(ticket.CreatedAt, time.Now(), workgroup)
						orm.Db.Table("openc3_tt_ticket").Where("id = ?", ticket.ID).Update(ticket)
					}
				}
				// mail
				go sendmail(oauser.(string), "ticket_add_worklog", ticket.ID, nil, obj)
			}
			c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
		}
	}
}

// ------- sys log --------

// 获取某个ticket的所有syslog
func GetCommonSysLog(c *gin.Context) {
	ticketid := c.Param("ticketid")
	obj := make([]model.CommonSysLog, 0)
	orm.Db.Table("openc3_tt_common_sys_log").Where("ticket_id = ?", ticketid).Order("id desc").Find(&obj)
	c.JSON(http.StatusOK, status_200(obj))
}

// 添加 sys log
func addCommonSysLog(ticket model.Ticket, operuser, opertype, opercolumn, content string) {
	var syslog model.CommonSysLog
	syslog.TicketId = ticket.ID
	syslog.Content = strings.TrimSpace(content)
	syslog.OperType = opertype
	syslog.OperColumn = opercolumn
	syslog.OperUser = operuser
	orm.Db.Create(&syslog)
}

// -------- i18n --------

func GetCommonI18n(c *gin.Context) {
	orm.Db.SingularTable(true)
	obj := make([]model.CommonLang, 0)
	orm.Db.Table("openc3_tt_common_lang").Find(&obj)
	c.JSON(http.StatusOK, status_200(obj))
}

func PutCommonI18n(c *gin.Context) {
	orm.Db.SingularTable(true)
	id := c.Param("id")
	var obj model.CommonLang
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_common_lang").Where("id = ?", id).Update(obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}
