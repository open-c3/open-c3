package handler

import (
	"openc3.org/trouble-ticketing/config"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"reflect"
	"strconv"
	"strings"
	"time"

	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"
	"github.com/jinzhu/gorm"

	"github.com/gin-gonic/gin"
)

var TTstatus = map[string]bool{
	"assigned": true,
	"wip":      true,
	"pending":  true,
	"resolved": true,
	"closed":   true,
}

// ---------- 获取事件 ----------

// 获取某个事件基本信息
func GetTicket(c *gin.Context) {
	type ticket struct {
		model.Ticket
		Attachment       []model.TicketAttachment `json:"attachment"`
		ResponseDeadline time.Time                `json:"response_deadline"`
		ResolveDeadline  time.Time                `json:"resolve_deadline"`
		ResponseTimeout  bool                     `json:"response_timeout"`
		ResolveTimeout   bool                     `json:"resolve_timeout"`
		ResolveDays      int64                    `json:"resolve_days"`
	}
	id := c.Param("id")
	var obj ticket
	var count int64
	if len(id) == 12 {
		orm.Db.Where("no = ?", id).First(&obj).Count(&count)
	} else {
		orm.Db.Where("id = ?", id).First(&obj).Count(&count)
	}
	if count == 0 {
		c.JSON(http.StatusOK, status_404(fmt.Sprintf("%s not found", id)))
		return
	}

	// 获取attachment
	attachment := make([]model.TicketAttachment, 0)
	orm.Db.Where("ticket_id = ?", obj.ID).Find(&attachment)
	obj.Attachment = attachment

	// get group
	var workgroup model.BaseGroup
	orm.Db.Where("id = ?", obj.Workgroup).First(&workgroup)
	// sla
	var impact model.BaseImpact
	orm.Db.Table("openc3_tt_base_impact").Where("id = ?", obj.Impact).First(&impact)
	obj.ResponseDeadline, obj.ResolveDeadline, obj.ResponseTimeout, obj.ResolveTimeout = CalTicketDeadline(impact, workgroup, obj.Ticket)

	obj.ResolveDays = CalTicketResolveDays(obj.Ticket, workgroup)

	// return
	c.JSON(http.StatusOK, status_200(obj))
}

// ----------  添加事件 ----------
type ticket struct {
	ID         int64         `json:"-"`
	No         string        `json:"-"`
	SubmitUser string        `json:"submit_user" binding:"required"`
	ApplyUser  string        `json:"apply_user" binding:"required"`
	Impact     int64         `json:"impact" binding:"required"`
	Category   int64         `json:"category" binding:"required"`
	Type       int64         `json:"type" binding:"required"`
	Item       int64         `json:"item" binding:"required"`
	Workgroup  int64         `json:"workgroup" binding:"required"`
	GroupUser  int64 		 `json:"group_user"`
	Title      string        `json:"title" binding:"required"`
	Content    string        `json:"content" binding:"required"`
	EmailList  string        `json:"email_list"`
	CreatedAt  time.Time     `json:"-"`
}

// pre 生成编号
func (t *ticket) BeforeCreate() {
	type result struct {
		AutoIncrement int64
	}
	var r result
	orm.Db.Raw(fmt.Sprintf("select auto_increment from information_schema.tables where table_schema = '%s' and table_name = 'openc3_tt_ticket';", config.Config().Dbname)).Scan(&r)
	t.EmailList = strings.Trim(strings.TrimSpace(t.EmailList), ";")
	t.No = fmt.Sprintf("TT%010d", r.AutoIncrement)
}

// after 发送邮件
func (t *ticket) AfterCreate() {
	if t.ID > 0 {

		newNo := fmt.Sprintf("TT%010d", t.ID)
		if newNo != t.No {
			t.No = newNo
			orm.Db.Table("openc3_tt_ticket").Where("id = ?", t.ID).Updates(t)
		}

		go sendmail("", "ticket_submit", t.ID, nil)
		// syslog
		go func() {
			var syslog model.CommonSysLog
			syslog.OperUser = t.SubmitUser
			syslog.OperType = "add"
			syslog.OperColumn = "ttno"
			syslog.Content = t.No
			syslog.TicketId = t.ID
			orm.Db.Create(&syslog)
		}()
	}

}

// 添加事件
func PostTicket(c *gin.Context) {

	var obj ticket

	if c.BindJSON(&obj) == nil {

		// check cti
		if !CheckCTIRelation(obj.Category, obj.Type, obj.Item) {
			c.JSON(http.StatusOK, status_400("cti error"))
			return
		}

		d := orm.Db.Create(&obj)
		if err := d.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
		} else {
			if d.RowsAffected == 1 {
				c.JSON(http.StatusOK, status_200(obj.ID))
			} else {
				c.JSON(http.StatusOK, status_400("add error"))
			}
		}
	}
}

// ----------  更新事件 ----------
func PutTicket(c *gin.Context) {
	var obj model.Ticket
	err := c.BindJSON(&obj)
	if err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}
	id := c.Param("id")
	// - id check
	if id != strconv.FormatInt(obj.ID, 10) {
		c.JSON(http.StatusOK, status_403("id does not match."))
		return
	}

	oauser, _ := c.Get("oauser")
	userEmail, ok := oauser.(string)
	if !ok {
		c.JSON(http.StatusOK, status_400(fmt.Sprintf("oauser邮箱地址从cookie中提取失败")))
		return
	}

	affected, err := updateTicket(obj, userEmail)
	if err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}

	c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	return
}

func updateTicket(obj model.Ticket, userEmail string) (int64, error) {
	id := obj.ID
	now := time.Now()

	// - check cti
	if !CheckCTIRelation(obj.Category, obj.Type, obj.Item) {
		return 0, errors.New(fmt.Sprintf("cti error"))
	}

	// - get old ticket
	var oldTicket model.Ticket
	err := orm.Db.Where("id = ?", id).First(&oldTicket).Error
	if err != nil {
		return 0, err
	}

	// - check if ticket closed
	if !oldTicket.ClosedTime.IsZero() {
		return 0, errors.New(fmt.Sprintf("Ticket is closed."))
	}

	// -- status fixed
	if obj.Status != "" && !TTstatus[obj.Status] {
		obj.Status = oldTicket.Status
	}

	// get workgroup
	var workgroup model.BaseGroup
	orm.Db.Where("id = ?", oldTicket.Workgroup).First(&workgroup)

	// -- 'resolved' status check
	if obj.Status == "resolved" {
		if len(obj.RootCause) < 2 || len(obj.Solution) < 2 {
			return 0, errors.New(fmt.Sprintf("Need rootcause and solution."))
		}
		if oldTicket.Status != "resolved" {

			obj.ResolveTime = now
			obj.ResolveCost = CalWorktimeCost(oldTicket.CreatedAt, now, workgroup)
			// 如果没响应，则在被解决时，响应时间＝解决时间
			if oldTicket.ResponseTime.IsZero() {
				obj.ResponseTime = now
				obj.ResponseCost = obj.ResolveCost
			}
		}
	}

	// - set response time
	if oldTicket.ResponseTime.IsZero() {
		var group model.BaseGroupUser
		// check priv
		if !orm.Db.Where("email = ? and group_id = ?", userEmail, oldTicket.Workgroup).First(&group).RecordNotFound() {
			obj.ResponseTime = now
			obj.ResponseCost = CalWorktimeCost(oldTicket.CreatedAt, now, workgroup)
		}
	}

	// - update old ticket
	//db := orm.Db.Table("openc3_tt_ticket").Where("id = ?", id).Omit("closed_time").Updates(obj)
	db := orm.Db.Exec("SET session sql_mode = '';").Model(&obj)

	// - check group_user null
	if obj.GroupUser == 0 && oldTicket.GroupUser != 0 {
		db.Update("group_user", gorm.Expr("NULL"))
		if db.Error == nil {
			var syslog model.CommonSysLog
			syslog.OperUser = userEmail
			syslog.OperType = "update"
			syslog.OperColumn = "group_user"
			syslog.TicketId = oldTicket.ID
			syslog.OperPre = fmt.Sprintf("%d", oldTicket.GroupUser)
			syslog.OperAfter = fmt.Sprintf("%d", obj.GroupUser)
			orm.Db.Create(&syslog)
		}
	}

	if obj.ResponseTime.IsZero() && obj.ResolveTime.IsZero() {
		db = db.Omit("closed_time", "response_time", "resolve_time").Updates(obj)
	}
	if obj.ResponseTime.IsZero() && !obj.ResolveTime.IsZero() {
		db = db.Omit("closed_time", "response_time").Updates(obj)
	}
	if !obj.ResponseTime.IsZero() && obj.ResolveTime.IsZero() {
		db = db.Omit("closed_time", "resolve_time").Updates(obj)
	}
	if !obj.ResponseTime.IsZero() && !obj.ResolveTime.IsZero() {
		db = db.Omit("closed_time").Updates(obj)
	}
	if err := db.Error; err != nil {
		return 0, err
	}

	affected := db.RowsAffected

	// - log && email
	if affected > 0 {

		// - check group&user
		if !CheckGroupUserRelation(obj.Workgroup, obj.GroupUser) {
			orm.Db.Model(&obj).Update("group_user", gorm.Expr("NULL"))
		}

		// log columns
		var logColumns = map[string]bool{
			"status":     true,
			"impact":     true,
			"category":   true,
			"type":       true,
			"item":       true,
			"workgroup":  true,
			"group_user": true,
			"title":      true,
			"content":    true,
			"email_list": true,
			"root_cause": true,
			"solution":   true,
			"apply_user": true,
		}
		// [only update] columns
		var updateColumns = map[string]bool{
			"status":     true,
			"impact":     true,
			"category":   true,
			"type":       true,
			"item":       true,
			"title":      true,
			"content":    true,
			"email_list": true,
			"apply_user": true,
		}
		// [reassign] columns
		var reassignColumns = map[string]bool{
			"workgroup":  true,
			"group_user": true,
		}
		// [solution] columns
		var solutionColumns = map[string]bool{
			"root_cause": true,
			"solution":   true,
		}
		// 可能触发的3类邮件，update/update_reassign/update_solution
		modifyMail := false
		reassignMail := false
		solutionMail := false

		// - pre/after diff
		t := reflect.TypeOf(obj)
		newVo := reflect.ValueOf(obj)
		oldVo := reflect.ValueOf(oldTicket)

		for i := 0; i < newVo.NumField(); i++ {

			newV := newVo.Field(i)
			oldV := oldVo.Field(i)
			fieldName := t.Field(i).Tag.Get("json")

			if logColumns[fieldName] {

				// syslog
				var syslog model.CommonSysLog
				syslog.OperUser = userEmail
				syslog.OperType = "update"
				syslog.OperColumn = fieldName
				syslog.TicketId = oldTicket.ID

				if newV.Type().Name() == "int64" && newV.Int() != 0 && newV.Int() != oldV.Int() {
					// -> syslog
					syslog.OperPre = fmt.Sprintf("%v", oldV.Int())
					syslog.OperAfter = fmt.Sprintf("%v", newV.Int())
					orm.Db.Create(&syslog)
					// 重新指派->mail
					if reassignColumns[fieldName] {
						reassignMail = true
					}
					// solution->mail
					if solutionColumns[fieldName] {
						solutionMail = true
					}
					// only update->mail
					if updateColumns[fieldName] {
						modifyMail = true
					}

				}
				if newV.Type().Name() == "string" && newV.String() != "" && newV.String() != oldV.String() {
					// -> syslog
					syslog.OperPre = oldV.String()
					syslog.OperAfter = newV.String()
					orm.Db.Create(&syslog)
					// 重新指派->mail
					if reassignColumns[fieldName] {
						reassignMail = true
					}
					// solution->mail
					if solutionColumns[fieldName] {
						solutionMail = true
					}
					// only update->mail
					if updateColumns[fieldName] {
						modifyMail = true
					}

				}
			}
		}

		// mail
		if modifyMail {
			go sendmail(userEmail, "ticket_update", obj.ID, nil)
		}
		if reassignMail {
			go sendmail(userEmail, "ticket_update_reassign", obj.ID, &oldTicket)
		}
		if solutionMail {
			go sendmail(userEmail, "ticket_update_solution", obj.ID, nil)
		}

	}
	return affected, nil
}


/* status flow */

// ---------- 获取事件状态流日志 ----------
func GetTicketStatusFlowLog(c *gin.Context) {
	ticketid := c.Param("ticketid")
	obj := make([]model.CommonSysLog, 0)
	orm.Db.Where("ticket_id = ? and oper_column='status'", ticketid).Find(&obj)
	c.JSON(http.StatusOK, status_200(obj))
}

type JsonNullInt64 struct {
	sql.NullInt64
}

func (v JsonNullInt64) MarshalJSON() ([]byte, error) {
	if v.Valid {
		return json.Marshal(v.Int64)
	} else {
		return json.Marshal(nil)
	}
}

func (v *JsonNullInt64) UnmarshalJSON(data []byte) error {
	// Unmarshalling into a pointer will let us detect null
	var x *int64
	if err := json.Unmarshal(data, &x); err != nil {
		return err
	}
	if x != nil {
		v.Valid = true
		v.Int64 = *x
	} else {
		v.Valid = false
	}
	return nil
}
