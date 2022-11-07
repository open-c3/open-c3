package handler

import (
	"openc3.org/trouble-ticketing/model"
	"errors"
	"fmt"
	"net/http"
	"strings"

	"openc3.org/trouble-ticketing/config"
	"openc3.org/trouble-ticketing/orm"
	"github.com/gin-gonic/gin"
)

// 第三方系统添加事件
func PublicPostTicket(c *gin.Context) {

	type reqT struct {
		System    string `json:"system" binding:"required"`
		Type      string `json:"type" binding:"required"`
		Title     string `json:"title" binding:"required"`
		Content   string `json:"content" binding:"required"`
		EmailList string `json:"email_list"`

		Impact    int64 `json:"impact"`
		C         int64 `json:"c"`
		T         int64 `json:"t"`
		I         int64 `json:"i"`
		Workgroup int64 `json:"workgroup"`

		SubmitUser string `json:"submit_user"`
		ApplyUser  string `json:"apply_user"`
	}
	var req reqT

	if c.BindJSON(&req) == nil {
		fmt.Println(req)
		var obj ticket

		// bpm
		if req.System == "BPM" {

			if req.Type == "manual" {

				if strings.TrimSpace(req.ApplyUser) == "" {
					c.JSON(http.StatusOK, status_400("apply user reqiured"))
					return
				}

				obj.SubmitUser = config.Config().Mail.SysMail
				obj.ApplyUser = req.ApplyUser
				obj.Impact = int64(5)
				obj.Category = int64(1)
				obj.Type = int64(6)
				obj.Item = int64(60)
				obj.Workgroup = req.Workgroup
				obj.Title = req.Title
				obj.Content = req.Content
				obj.EmailList = req.EmailList

				d := orm.Db.Create(&obj)
				if err := d.Error; err != nil {
					c.JSON(http.StatusOK, status_400(err.Error()))
					return
				}

				err := assignTtToSpecifiedEmail(obj.No, obj.Title, obj.ApplyUser)
				if err != nil {
					c.JSON(http.StatusOK, status_400(err.Error()))
					return
				}
				c.JSON(http.StatusOK, status_200(obj.No))
				return
			}

			// AI
		} else if req.System == "AI" {

			// 用户OA部门信息变动
			if req.Type == "dept_change" {

				obj.ApplyUser = config.Config().Mail.SysMail
				obj.SubmitUser = config.Config().Mail.SysMail
				obj.Impact = int64(5)
				obj.Category = int64(1)
				obj.Type = int64(1)
				obj.Item = int64(1)
				obj.Workgroup = int64(2)
				obj.Title = req.Title
				obj.Content = req.Content
				obj.EmailList = req.EmailList

				d := orm.Db.Create(&obj)
				if err := d.Error; err != nil {
					c.JSON(http.StatusOK, status_400(err.Error()))
					return
				}

				err := assignTtToSpecifiedEmail(obj.No, obj.Title, obj.ApplyUser)
				if err != nil {
					c.JSON(http.StatusOK, status_400(err.Error()))
					return
				}
				c.JSON(http.StatusOK, status_200(obj.No))
			}

			// 监控系统
		} else if req.System == "Monitor" {

			if req.Type == "desktop" {

				obj.SubmitUser = config.Config().Mail.SysMail
				obj.ApplyUser = config.Config().Mail.SysMail
				obj.Impact = int64(5)
				obj.Category = int64(1)
				obj.Type = int64(3)
				obj.Item = int64(32)
				obj.Workgroup = int64(2)
				obj.Title = req.Title
				obj.Content = req.Content
				obj.EmailList = req.EmailList

				if req.Impact > 0 {
					obj.Impact = req.Impact
				}
				if req.C > 0 {
					obj.Category = req.C
				}
				if req.T > 0 {
					obj.Type = req.T
				}
				if req.I > 0 {
					obj.Item = req.I
				}
				if req.Workgroup > 0 {
					obj.Workgroup = req.Workgroup
				}

				d := orm.Db.Create(&obj)

				if err := d.Error; err != nil {
					c.JSON(http.StatusOK, status_400(err.Error()))
				} else {
					if d.RowsAffected == 1 {
						c.JSON(http.StatusOK, status_200(obj.No))
					} else {
						c.JSON(http.StatusOK, status_400("add error"))
					}
				}

			}
			// ACD
		} else if req.System == "ACD" {

			if req.Type == "common" {

				obj.SubmitUser = config.Config().Mail.SysMail
				obj.ApplyUser = config.Config().Mail.SysMail
				obj.Impact = int64(5)
				obj.Category = int64(1)
				obj.Type = int64(1)
				obj.Item = int64(11)
				obj.Title = req.Title
				obj.Content = req.Content
				obj.EmailList = req.EmailList

				if req.Workgroup > 0 {
					obj.Workgroup = req.Workgroup
				} else {
					c.JSON(http.StatusOK, status_400("workgroup error"))
					return
				}

				d := orm.Db.Create(&obj)

				if err := d.Error; err != nil {
					c.JSON(http.StatusOK, status_400(err.Error()))
				} else {
					if d.RowsAffected == 1 {
						c.JSON(http.StatusOK, status_200(obj.No))
					} else {
						c.JSON(http.StatusOK, status_400("add error"))
					}
				}

			}
			// CDN
		} else if req.System == "CDN" {

			if req.Type == "common" {

				obj.SubmitUser = config.Config().Mail.SysMail
				obj.ApplyUser = config.Config().Mail.SysMail
				obj.Impact = int64(5)
				obj.Category = int64(1)
				obj.Type = int64(1)
				obj.Item = int64(12)
				obj.Workgroup = int64(5)
				obj.Title = req.Title
				obj.Content = req.Content
				obj.EmailList = req.EmailList

				d := orm.Db.Create(&obj)

				if err := d.Error; err != nil {
					c.JSON(http.StatusOK, status_400(err.Error()))
				} else {
					if d.RowsAffected == 1 {
						c.JSON(http.StatusOK, status_200(obj.No))
					} else {
						c.JSON(http.StatusOK, status_400("add error"))
					}
				}

			}

			// common
		} else if req.System == "All" {

			if req.Type == "diy" {

				obj.ApplyUser = config.Config().Mail.SysMail

				if strings.TrimSpace(req.ApplyUser) != "" {
					obj.ApplyUser = strings.TrimSpace(req.ApplyUser)
				}

				obj.SubmitUser = config.Config().Mail.SysMail
				obj.Title = req.Title
				obj.Content = req.Content
				obj.EmailList = req.EmailList

				if req.Impact > 0 {
					obj.Impact = req.Impact
				}
				if req.C > 0 {
					obj.Category = req.C
				}
				if req.T > 0 {
					obj.Type = req.T
				}
				if req.I > 0 {
					obj.Item = req.I
				}
				if req.Workgroup > 0 {
					obj.Workgroup = req.Workgroup
				}
				if req.Impact <= 0 || req.C <= 0 || req.T <= 0 || req.I <= 0 || req.Workgroup <= 0 {
					c.JSON(http.StatusOK, status_400("params error"))
					return
				}

				if !CheckCTIRelation(req.C, req.T, req.I) {
					c.JSON(http.StatusOK, status_400("cti error"))
					return
				}

				d := orm.Db.Create(&obj)

				if err := d.Error; err != nil {
					c.JSON(http.StatusOK, status_400(err.Error()))
				} else {
					if d.RowsAffected == 1 {

						err := assignTtToSpecifiedEmail(obj.No, obj.Title, obj.ApplyUser)
						if err != nil {
							c.JSON(http.StatusOK, status_400(err.Error()))
							return
						}

						c.JSON(http.StatusOK, status_200(obj.No))
					} else {
						c.JSON(http.StatusOK, status_400("add error"))
					}
				}

			}
		} else {
			// default
			c.JSON(http.StatusOK, status_400("match error!"))
			return
		}

	}
}

func assignTtToSpecifiedEmail(ttNumber string, title string, userEmail string) error {
	var obj model.Ticket
	var count int64
	orm.Db.Where("no = ?", ttNumber).First(&obj).Count(&count)
	if count == 0 {
		return errors.New(fmt.Sprintf("%s not found", ttNumber))
	}

	reminderList := config.Config().ReminderList
	for _, reminder := range reminderList {
		if reminder.Enable && len(reminder.Users) > 0 {
			var found bool
			for _, k := range reminder.Keyword {
				if strings.Contains(title, k) {
					found = true
					break
				}
			}

			if found {
				obj.Workgroup = reminder.Users[0].WorkGroupId
				obj.GroupUser = reminder.Users[0].GroupUserId
				_, err := updateTicket(obj, userEmail)
				if err != nil {
					return err
				}
				for _, u := range reminder.Users {
					var user model.BaseGroupUser
					orm.Db.Where("id = ?", u.GroupUserId).First(&user)
					sendmail(user.Email, "ticket_update", obj.ID, nil)
				}
			}
		}
	}

	return nil
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
//
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
