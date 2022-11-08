package handler

import (
	"fmt"
	"net/http"
	"reflect"
	"time"

	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"

	"github.com/gin-gonic/gin"
)

// 搜索
func SearchList(c *gin.Context) {

	type searchFilter struct {
		Category    int64     `json:"category"`
		Impact      int64     `json:"impact"`
		Item        int64     `json:"item"`
		Status      string    `json:"status"`
		Type        int64     `json:"type"`
		Workgroup   int64     `json:"workgroup"`
		GroupUser   string    `json:"group_user" gorm:"-"`
		Keyword     string    `json:"keyword" gorm:"-"`
		CreateStart time.Time `json:"create_start" gorm:"-"`
		CreateEnd   time.Time `json:"create_end" gorm:"-"`
		ProcessingTime	string	`json:"processing_time" gorm:"-"`
	}

	var obj searchFilter
	var blank searchFilter
	tickets := make([]STicket, 0)

	if c.BindJSON(&obj) == nil {

		if !reflect.DeepEqual(obj, blank) {

			db := orm.Db.Table("openc3_tt_ticket").Select(selectCols).Where(&obj)

			// group user
			if obj.GroupUser != "" {
				//if match, _ := regexp.MatchString(`^[0-9a-zA-Z@]+$`, obj.GroupUser); match {
				baseusers := make([]model.BaseGroupUser, 0)
				if err := orm.Db.Where("email like ?", fmt.Sprintf("%%%s%%", obj.GroupUser)).Find(&baseusers).Error; err != nil {
					c.JSON(http.StatusOK, status_400(err))
					return
				}
				myArr := make([]int64, 0)
				for _, u := range baseusers {
					myArr = append(myArr, u.ID)
				}
				db = db.Where("group_user in (?)", myArr)
				//}
			}

			// keyword
			if obj.Keyword != "" {
				db = db.Where("title like ? or content like ? or no = ?", fmt.Sprintf("%%%s%%", obj.Keyword), fmt.Sprintf("%%%s%%", obj.Keyword), obj.Keyword)
			}

			// create start
			if !obj.CreateStart.IsZero() {
				start := obj.CreateStart.Local().Format("2006-01-02")
				db = db.Where("created_at >= ?", start)
			}

			// create end
			if !obj.CreateEnd.IsZero() {
				end := obj.CreateEnd.Local().AddDate(0, 0, 1).Format("2006-01-02")
				db = db.Where("created_at < ?", end)
			}
			//processing_time
			if obj.ProcessingTime != ""{
				if obj.Status == "resolved" || obj.Status =="closed"{
					db = db.Where("unix_timestamp(resolve_time) - unix_timestamp(created_at) >= ?*3600", fmt.Sprintf("%s",obj.ProcessingTime))
				}else {
					db = db.Where("unix_timestamp(now()) - unix_timestamp(created_at) >= ?*3600", fmt.Sprintf("%s",obj.ProcessingTime))
				}
			}

			// query
			if err := db.Order("id desc").Find(&tickets).Error; err != nil {
				c.JSON(http.StatusOK, status_400(err))
				return
			}
			c.JSON(http.StatusOK, status_200(GetTicketsRemain(tickets)))
		} else {
			c.JSON(http.StatusOK, status_200(tickets))
		}

	}

}

// 检索某个用户所有未关闭的事件
func SearchOpenTicketForUser(c *gin.Context) {

	type searchFilter struct {
		GroupId int64 `json:"group_id" gorm:"-"`
		Id      int64 `json:"id" gorm:"-"`
	}

	var obj searchFilter
	tickets := make([]STicket, 0)

	if c.BindJSON(&obj) == nil {

		if err := orm.Db.Table("openc3_tt_ticket").Select(selectCols).Where("group_user=? and workgroup=?  and status!='closed'", obj.Id, obj.GroupId).Order("id desc").Find(&tickets).Error; err != nil {
			c.JSON(http.StatusOK, status_400(err))
			return
		}

		c.JSON(http.StatusOK, status_200(GetTicketsRemain(tickets)))

	}

}
