package handler

import (
	"fmt"
	"net/http"
	"time"

	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"

	"github.com/gin-gonic/gin"
)

type STicket struct {
	model.Ticket
	ResponseDeadline time.Time `json:"response_deadline"`
	ResolveDeadline  time.Time `json:"resolve_deadline"`
	ResponseTimeout  bool      `json:"response_timeout"`
	ResolveTimeout   bool      `json:"resolve_timeout"`
}

var selectCols = []string{"id", "no", "submit_user", "apply_user", "status", "impact", "category", "type", "item", "title", "workgroup", "group_user", "email_list", "response_time", "resolve_time", "closed_time", "created_at"}

// 指派给我的未完成事件
func SearchAssignMe(c *gin.Context) {

	oauser, _ := c.Get("oauser")

	baseusers := make([]model.BaseGroupUser, 0)
	if err := orm.Db.Where("email = ?", oauser.(string)).Find(&baseusers).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	myArr := make([]int64, 0)
	for _, u := range baseusers {
		myArr = append(myArr, u.ID)
	}

	tickets := make([]STicket, 0)
	if err := orm.Db.Table("openc3_tt_ticket").Select(selectCols).Where("group_user in (?) and status!='resolved' and status!='closed'", myArr).Order("id desc").Find(&tickets).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	c.JSON(http.StatusOK, status_200(GetTicketsRemain(tickets)))
}

// 我提交的未完成事件
func SearchSelfsubmit(c *gin.Context) {
	tickets := make([]STicket, 0)
	oauser, _ := c.Get("oauser")
	if err := orm.Db.Table("openc3_tt_ticket").Select(selectCols).Where("submit_user = ? and status!='resolved' and status!='closed'", oauser.(string)).Order("id desc").Find(&tickets).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	c.JSON(http.StatusOK, status_200(GetTicketsRemain(tickets)))
}

// 抄送我的未完成事件
func SearchEmaillistMe(c *gin.Context) {
	tickets := make([]STicket, 0)
	oauser, _ := c.Get("oauser")
	if err := orm.Db.Table("openc3_tt_ticket").Select(selectCols).Where("email_list like ? and status!='resolved' and status!='closed'", fmt.Sprintf("%%%s%%", oauser.(string))).Order("id desc").Find(&tickets).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	c.JSON(http.StatusOK, status_200(GetTicketsRemain(tickets)))
}

// 级别1-2级的事件（30天内）
func SearchLevel12(c *gin.Context) {
	tickets := make([]STicket, 0)
	day30 := time.Now().AddDate(0, 0, -30).Format("2006-01-02 15:04:05")
	if err := orm.Db.Table("openc3_tt_ticket").Where("(impact = 1 or impact = 2) and created_at > ?", day30).Order("id desc").Find(&tickets).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	c.JSON(http.StatusOK, status_200(GetTicketsRemain(tickets)))
}

// 首页未完成事件菜单列表
func SearchMenuList(c *gin.Context) {
	type listT struct {
		Group map[string][]STicket `json:"group"`
		Me    []STicket            `json:"me"`
	}
	list := new(listT)
	oauser, _ := c.Get("oauser")

	// 指派给我的
	baseusers := make([]model.BaseGroupUser, 0)
	if err := orm.Db.Where("email = ?", oauser.(string)).Find(&baseusers).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	myArr := make([]int64, 0)
	myGroupArr := make([]int64, 0)
	for _, u := range baseusers {
		myArr = append(myArr, u.ID)
		myGroupArr = append(myGroupArr, u.GroupId)
	}
	tickets := make([]STicket, 0)
	if err := orm.Db.Table("openc3_tt_ticket").Where("group_user in (?) and status!='resolved' and status!='closed'", myArr).Order("id desc").Find(&tickets).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	list.Me = make([]STicket, 0)
	for _, t := range GetTicketsRemain(tickets) {
		list.Me = append(list.Me, t)
	}

	// 我的解决组的
	basegroups := make([]model.BaseGroup, 0)
	if err := orm.Db.Where("id in (?)", myGroupArr).Find(&basegroups).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	tickets_g := make([]STicket, 0)
	if err := orm.Db.Table("openc3_tt_ticket").Where("workgroup in (?) and status!='resolved' and status!='closed'", myGroupArr).Order("id desc").Find(&tickets_g).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	list.Group = make(map[string][]STicket)
	for _, t := range GetTicketsRemain(tickets_g) {
		for _, g := range basegroups {
			if t.Workgroup == g.ID {
				list.Group[g.GroupName] = append(list.Group[g.GroupName], t)
			}
		}
	}

	c.JSON(http.StatusOK, status_200(list))
}

// 我的事件（提交人|申请人==我）
func SearchMyticket(c *gin.Context) {
	tickets := make([]STicket, 0)
	oauser, _ := c.Get("oauser")
	if err := orm.Db.Table("openc3_tt_ticket").Select(selectCols).Where("submit_user = ? or apply_user = ?", oauser.(string), oauser.(string)).Order("id desc").Find(&tickets).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	c.JSON(http.StatusOK, status_200(GetTicketsRemain(tickets)))
}
