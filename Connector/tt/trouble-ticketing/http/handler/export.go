package handler

import (
	"bufio"
	"bytes"
	"fmt"
	"html"
	"net/http"
	"regexp"
	"strings"
	"time"

	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"

	"github.com/gin-gonic/gin"
	"github.com/tealeg/xlsx"
)

// 导出事件列表
func ExportTickets(c *gin.Context) {

	type ticketS struct {
		model.Ticket
		Attachment      string
		Impact_         string
		Category_       string
		Type_           string
		Item_           string
		Workgroup_      string
		GroupUser_      string
		ResponseTimeout string
		ResolveTimeout  string
	}

	ids_arr := strings.Split(c.PostForm("ids"), ",")

	if len(ids_arr) == 0 {
		c.JSON(http.StatusOK, status_400("no ids"))
		return
	}

	exfile := xlsx.NewFile()
	exsheet, err := exfile.AddSheet("CMCM")

	headerstyle := xlsx.NewStyle()
	headerstyle.Font = *xlsx.NewFont(12, "Microsoft YaHei")
	headerstyle.Alignment.Vertical = "center"
	headerstyle.ApplyFont = true
	headerstyle.ApplyAlignment = true

	// find tickets
	tickets := make([]ticketS, 0)
	orm.Db.Table("openc3_tt_ticket").Where("no in (?) or id in (?)", ids_arr, ids_arr).Find(&tickets)

	// tickets' IDs
	ticketsIds := make([]int64, 0)
	for _, t := range tickets {
		ticketsIds = append(ticketsIds, t.ID)
	}

	// metadata
	impacts := make([]model.BaseImpact, 0)
	categorys := make([]model.BaseCategory, 0)
	types := make([]model.BaseType, 0)
	items := make([]model.BaseItem, 0)
	groups := make([]model.BaseGroup, 0)
	users := make([]model.BaseGroupUser, 0)
	attachments := make([]model.TicketAttachment, 0)

	orm.Db.Select("level,name").Find(&impacts)
	orm.Db.Select("id,name").Find(&categorys)
	orm.Db.Select("id,name").Find(&types)
	orm.Db.Select("id,name").Find(&items)
	orm.Db.Select("id,group_name").Find(&groups)
	orm.Db.Select("id,email").Find(&users)
	orm.Db.Select("id, name, ticket_id").Where("ticket_id in (?)", ticketsIds).Find(&attachments)

	impactsM := make(map[int64]string)
	for _, v := range impacts {
		impactsM[v.Level] = v.Name
	}

	categorysM := make(map[int64]string)
	for _, v := range categorys {
		categorysM[v.ID] = v.Name
	}

	typesM := make(map[int64]string)
	for _, v := range types {
		typesM[v.ID] = v.Name
	}

	itemsM := make(map[int64]string)
	for _, v := range items {
		itemsM[v.ID] = v.Name
	}

	groupsM := make(map[int64]string)
	for _, v := range groups {
		groupsM[v.ID] = v.GroupName
	}

	usersM := make(map[int64]string)
	for _, v := range users {
		usersM[v.ID] = v.Email
	}

	attachmentsM := make(map[int64]string)
	for _, v := range attachments {
		attachmentsM[v.TicketId] += v.Name + ","
	}
	for k, _ := range attachmentsM {
		attachmentsM[k] = strings.TrimRight(attachmentsM[k], ",")
	}

	for k, ticket := range tickets {
		tickets[k].Impact_ = fmt.Sprintf("%d-%s", ticket.Impact, impactsM[ticket.Impact])
		tickets[k].Category_ = categorysM[ticket.Category]
		tickets[k].Type_ = typesM[ticket.Type]
		tickets[k].Item_ = itemsM[ticket.Item]
		tickets[k].Workgroup_ = groupsM[ticket.Workgroup]
		tickets[k].GroupUser_ = usersM[ticket.GroupUser]
		tickets[k].Attachment = attachmentsM[ticket.ID]

		tickets[k].ResponseTimeout = "未超时"
		if ticket.ResponseTimeoutSent > 0 {
			tickets[k].ResponseTimeout = "已超时"
		}
		tickets[k].ResolveTimeout = "未超时"
		if ticket.ResolveTimeoutSent > 0 {
			tickets[k].ResolveTimeout = "已超时"
		}
	}

	// title
	row := exsheet.AddRow()
	row.SetHeightCM(1.1)
	cell := row.AddCell()
	cell.Value = "Trouble Ticketing"
	cell = row.AddCell()
	cell.Value = time.Now().Format("2006-01-02 15:04:05")
	for _, c := range row.Cells {
		c.SetStyle(headerstyle)
	}

	row = exsheet.AddRow()
	cell = row.AddCell()
	cell.Value = "事件编号"
	cell = row.AddCell()
	cell.Value = "影响级别"
	cell = row.AddCell()
	cell.Value = "状态"
	cell = row.AddCell()
	cell.Value = "C"
	cell = row.AddCell()
	cell.Value = "T"
	cell = row.AddCell()
	cell.Value = "I"
	cell = row.AddCell()
	cell.Value = "标题"
	cell = row.AddCell()
	cell.Value = "内容"
	cell = row.AddCell()
	cell.Value = "工作组"
	cell = row.AddCell()
	cell.Value = "组员"
	cell = row.AddCell()
	cell.Value = "提交人"
	cell = row.AddCell()
	cell.Value = "申请人"
	cell = row.AddCell()
	cell.Value = "创建时间"
	cell = row.AddCell()
	cell.Value = "响应时间"
	cell = row.AddCell()
	cell.Value = "解决时间"
	cell = row.AddCell()
	cell.Value = "关闭时间"
	cell = row.AddCell()
	cell.Value = "响应SLA"
	cell = row.AddCell()
	cell.Value = "解决SLA"
	cell = row.AddCell()
	cell.Value = "抄送列表"
	cell = row.AddCell()
	cell.Value = "附件列表"
	cell = row.AddCell()
	cell.Value = "根本原因"
	cell = row.AddCell()
	cell.Value = "解决方案"

	for _, c := range exsheet.Cols {
		c.Width = 20
	}

	for _, ticket := range tickets {
		row = exsheet.AddRow()
		cell = row.AddCell()
		cell.Value = ticket.No
		cell = row.AddCell()
		cell.Value = ticket.Impact_
		cell = row.AddCell()
		cell.Value = ticket.Status
		cell = row.AddCell()
		cell.Value = ticket.Category_
		cell = row.AddCell()
		cell.Value = ticket.Type_
		cell = row.AddCell()
		cell.Value = ticket.Item_
		cell = row.AddCell()
		cell.Value = ticket.Title
		cell = row.AddCell()
		cell.Value = html2text(ticket.Content)
		cell = row.AddCell()
		cell.Value = ticket.Workgroup_
		cell = row.AddCell()
		cell.Value = ticket.GroupUser_
		cell = row.AddCell()
		cell.Value = ticket.SubmitUser
		cell = row.AddCell()
		cell.Value = ticket.ApplyUser
		cell = row.AddCell()
		cell.Value = ticket.CreatedAt.Format("2006-01-02 15:04:05")
		cell = row.AddCell()
		cell.Value = ticket.ResponseTime.Format("2006-01-02 15:04:05")
		cell = row.AddCell()
		cell.Value = ticket.ResolveTime.Format("2006-01-02 15:04:05")
		cell = row.AddCell()
		cell.Value = ticket.ClosedTime.Format("2006-01-02 15:04:05")
		cell = row.AddCell()
		cell.Value = ticket.ResponseTimeout
		cell = row.AddCell()
		cell.Value = ticket.ResolveTimeout
		cell = row.AddCell()
		cell.Value = ticket.EmailList
		cell = row.AddCell()
		cell.Value = ticket.Attachment
		cell = row.AddCell()
		cell.Value = html2text(ticket.RootCause)
		cell = row.AddCell()
		cell.Value = html2text(ticket.Solution)
	}

	exsheet.Name = fmt.Sprintf("TT-%d", len(tickets))

	/**/

	// return file bytes
	var b bytes.Buffer
	bWriter := bufio.NewWriter(&b)
	err = exfile.Write(bWriter)

	if err != nil {
		c.JSON(http.StatusOK, status_400(fmt.Sprintf("export error: %s", err.Error())))
		return
	}

	oauser, _ := c.Get("oauser")

	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=TT-%s.xlsx", oauser))
	c.Data(http.StatusOK, "", b.Bytes())

}

// html->text
func html2text(src string) string {

	reTag, _ := regexp.Compile("<[^>]*>")
	reBlank, _ := regexp.Compile(`\s`)

	removeTag := reTag.ReplaceAllString(src, " ")
	unHtml := html.UnescapeString(removeTag)
	removeBlank := reBlank.ReplaceAllString(unHtml, " ")
	ret := strings.TrimSpace(removeBlank)

	return ret
}
