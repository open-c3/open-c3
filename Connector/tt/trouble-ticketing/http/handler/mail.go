package handler

import (
	"bytes"
	"fmt"
	"html/template"
	"regexp"
	"strings"
	"time"

	"openc3.org/trouble-ticketing/util"

	"openc3.org/trouble-ticketing/config"
	"openc3.org/trouble-ticketing/funcs"
	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"
)

/**************************************/
// mail
/**************************************/

// email内容主元数据
type metadataType struct {
	No              string              `json:"no"`
	Impact          int64               `json:"impact"`
	Status          string              `json:"status"`
	Title           string              `json:"title"`
	Content         string              `json:"content"`
	RootCause       string              `json:"root_cause"`
	Solution        string              `json:"solution"`
	Category        string              `json:"category"`
	Type            string              `json:"type"`
	Item            string              `json:"item"`
	SubmitTime      time.Time           `json:"submit_time"`
	ResponseTime    time.Time           `json:"response_time"`
	ResolveTime     time.Time           `json:"resolve_time"`
	ClosedTime      time.Time           `json:"closed_time"`
	ApplyUserEmail  string              `json:"apply_user_email"`
	ApplyUserName   string              `json:"apply_user_name"`
	ApplyUserPhone  string              `json:"apply_user_phone"`
	ApplyUserSyb    string              `json:"apply_user_syb"`
	ApplyUserOnedpt string              `json:"apply_user_onedpt"`
	AssignGroupName string              `json:"assign_group_name"`
	AssignUserName  string              `json:"assign_user_name"`
	AssignUserEmail string              `json:"assign_user_email"`
	ModifyUserName  string              `json:"modify_user_name"`
	ModifyUserEmail string              `json:"modify_user_email"`
	ModifyTime      time.Time           `json:"modify_time"`
	NewWorklog      model.CommonWorkLog `json:"new_worklog"`
	Reply           []struct {
		OperUser  string    `json:"oper_user"`
		UserName  string    `json:"user_name"`
		Content   string    `json:"content"`
		TicketId  int64     `json:"ticket_id"`
		CreatedAt time.Time `json:"created_at"`
	} `json:"reply"`
	ResponseDeadline time.Time `json:"response_deadline"`
	ResolveDeadline  time.Time `json:"resolve_deadline"`
	ResponseTimeout  bool      `json:"response_timeout"`
	ResolveTimeout   bool      `json:"resolve_timeout"`
}

type ctiType struct {
	Category string `json:"category"`
	Type     string `json:"type"`
	Item     string `json:"item"`
}

type assignsType struct {
	AssignGroupName string `json:"assign_group_name"`
	AssignUserEmail string `json:"assign_user_email"`
}

type recipient struct {
	Users string
}

// send mail
// a-> 添加worklog时新log
func sendmail(modifyuser, mailtype string, ticketId int64, oldTicket *model.Ticket, a ...interface{}) {
	var (
		subject, body *string
		receivers     = make([]string, 0)
	)

	// 查询过的oa用户 暂存, 防止一个用户被多次请求查询
	oausers := make(map[string]funcs.UserInfo)

	// 所有邮件类型
	mailtypes := map[string]bool{
		"ticket_submit":          true, // 事件提交
		"ticket_update":          true, // 事件修改
		"ticket_update_reassign": true, // 事件修改-重新指派
		"ticket_update_solution": true, // 事件修改-solution
		"ticket_add_reply":       true, // 添加replylog
		"ticket_add_worklog":     true, // 添加worklog
		"ticket_closed":          true, // 关闭ticket
		"ticket_timeout":         true, // sla超时
	}
	if !mailtypes[mailtype] || ticketId < 1001 {
		fmt.Println("no mail type match!")
		return
	}

	// get current ticket
	var ticket model.Ticket
	err := orm.Db.Where("id = ?", ticketId).First(&ticket).Error
	if err != nil || ticket.ID == 0 {
		fmt.Println("get ticket err:", err)
		return
	}

	// get cti
	var cti ctiType
	orm.Db.Raw(fmt.Sprintf("select category,type,item from (select name category from openc3_tt_base_category where id=%d) as a,(select name type from openc3_tt_base_type where id=%d) as b,(select name item from openc3_tt_base_item where id=%d) as c", ticket.Category, ticket.Type, ticket.Item)).Scan(&cti)

	// get assign user/group name
	var assigns assignsType
	if ticket.GroupUser == 0 {
		orm.Db.Raw(fmt.Sprintf("select group_name assign_group_name from openc3_tt_base_group where id=%d", ticket.Workgroup)).Scan(&assigns)
	} else {
		orm.Db.Raw(fmt.Sprintf("select assign_group_name, assign_user_email from (select email assign_user_email from openc3_tt_base_group_user where id=%d) as a, (select group_name assign_group_name from openc3_tt_base_group where id=%d) as b", ticket.GroupUser, ticket.Workgroup)).Scan(&assigns)
	}

	// get modify user's oa info
	if _, exist := oausers[modifyuser]; !exist {
		modifyuseroa, err := funcs.GetUserInfo(modifyuser)
		if err != nil {
			funcs.PrintlnLog(fmt.Sprintf("sendmaill.GetUserInfo. get modifyuser info: err: %v", err))
		}
		oausers[modifyuser] = modifyuseroa
	}
	// get apply user's oa info
	if _, exist := oausers[ticket.ApplyUser]; !exist {
		applyuser, err := funcs.GetUserInfo(ticket.ApplyUser)
		if err != nil {
			funcs.PrintlnLog(fmt.Sprintf("sendmaill.GetUserInfo. get applyuser info: err: %v", err))
		}
		oausers[ticket.ApplyUser] = applyuser
	}
	// get assign user's oa info
	if _, exist := oausers[assigns.AssignUserEmail]; !exist {
		assignuser, err := funcs.GetUserInfo(assigns.AssignUserEmail)
		if err != nil {
			funcs.PrintlnLog(fmt.Sprintf("sendmaill.GetUserInfo. get assignuser info: err: %v", err))
		}
		oausers[assigns.AssignUserEmail] = assignuser
	}

	var metadata metadataType
	metadata.No = ticket.No
	metadata.Impact = ticket.Impact
	metadata.Status = ticket.Status
	metadata.Title = ticket.Title
	metadata.Content = ticket.Content
	metadata.RootCause = ticket.RootCause
	metadata.Solution = ticket.Solution
	metadata.SubmitTime = ticket.CreatedAt
	metadata.ResponseTime = ticket.ResponseTime
	metadata.ResolveTime = ticket.ResolveTime
	metadata.ClosedTime = ticket.ClosedTime
	metadata.ApplyUserEmail = ticket.ApplyUser
	metadata.ApplyUserName = oausers[ticket.ApplyUser].AccountName
	metadata.ApplyUserPhone = oausers[ticket.ApplyUser].Mobile
	metadata.ApplyUserSyb = oausers[ticket.ApplyUser].SybDeptName
	metadata.ApplyUserOnedpt = oausers[ticket.ApplyUser].OneDeptName
	metadata.Category = cti.Category
	metadata.Type = cti.Type
	metadata.Item = cti.Item
	metadata.AssignGroupName = assigns.AssignGroupName
	metadata.AssignUserEmail = assigns.AssignUserEmail
	metadata.AssignUserName = oausers[assigns.AssignUserEmail].AccountName
	metadata.ModifyUserName = oausers[modifyuser].AccountName
	metadata.ModifyUserEmail = modifyuser
	metadata.ModifyTime = time.Now()

	// ticket_submit
	if mailtype == "ticket_submit" {
		subject, body, receivers, err = getSubmitTypeTicketInfo(ticket, metadata)
		if err != nil {
			return
		}
	}
	// ticket_update
	if mailtype == "ticket_update" {
		subject, body, receivers, err = getUpdateTypeTicketInfo(ticket, metadata)
		if err != nil {
			return
		}
	}
	// ticket_update_reassign
	if mailtype == "ticket_update_reassign" {
		subject, body, receivers, err = getReAssignTypeTicketInfo(ticket, metadata)
		if err != nil {
			return
		}

		// 原事件 指派人/工作组邮箱
		var rcpt_cc1 recipient
		var rcpt_cc2 recipient
		orm.Db.Table("openc3_tt_base_group_user").Select("email users").Where("id = ?", oldTicket.GroupUser).Find(&rcpt_cc1)
		orm.Db.Table("openc3_tt_base_group").Select("group_email users").Where("id = ?", oldTicket.Workgroup).Find(&rcpt_cc2)
		receivers = append(receivers, rcpt_cc1.Users, rcpt_cc2.Users)

	}
	// ticket_update_solution
	if mailtype == "ticket_update_solution" {
		subject, body, receivers, err = getUpdateSolutionTypeTicketInfo(ticket, metadata)
		if err != nil {
			return
		}
	}
	// ticket_add_reply
	if mailtype == "ticket_add_reply" {
		// get relay logs
		orm.Db.Table("openc3_tt_common_reply_log").Where("ticket_id = ?", ticket.ID).Order("id desc").Find(&metadata.Reply)
		for k, r := range metadata.Reply {
			if _, exist := oausers[r.OperUser]; !exist {
				oauser, _ := funcs.GetUserInfo(r.OperUser)
				oausers[r.OperUser] = oauser
			}
			metadata.Reply[k].UserName = oausers[r.OperUser].AccountName
		}
		subject, body, receivers, err = getAddReplyTypeTicketInfo(ticket, metadata)
		if err != nil {
			return
		}
	}
	// ticket_add_worklog
	if mailtype == "ticket_add_worklog" {
		metadata.NewWorklog = a[0].(model.CommonWorkLog)
		subject, body, receivers, err = getAddWorkLogTypeTicketInfo(ticket, metadata)
		if err != nil {
			return
		}
	}
	// ticket_closed
	if mailtype == "ticket_closed" {
		// get group
		var workgroup model.BaseGroup
		orm.Db.Where("id = ?", ticket.Workgroup).First(&workgroup)
		// get impact
		var impact model.BaseImpact
		orm.Db.Where("id = ?", ticket.Impact).First(&impact)

		// sla
		responseDeadline, resolveDeadline, responseTimeout, resolveTimeout := CalTicketDeadline(impact, workgroup, ticket)
		metadata.ResponseDeadline = responseDeadline
		metadata.ResolveDeadline = resolveDeadline
		metadata.ResponseTimeout = responseTimeout
		metadata.ResolveTimeout = resolveTimeout

		subject, body, receivers, err = getCloseTypeTicketInfo(ticket, metadata)
		if err != nil {
			return
		}
	}
	// ticket_timeout
	if mailtype == "ticket_timeout" {
		metadata.ResponseDeadline = a[0].(time.Time)
		metadata.ResolveDeadline = a[1].(time.Time)
		metadata.ResponseTimeout = a[2].(bool)
		metadata.ResolveTimeout = a[3].(bool)
		subject, body, receivers, err = getTimeoutTypeTicketInfo(ticket, metadata)
		if err != nil {
			return
		}
	}
	receivers = util.RemoveDuplicateStr(receivers)

	funcs.PrintlnLog(fmt.Sprintf("sendmail. email info: subject = %v, body = %v, receivers = %v", *subject, *body, receivers))

	for _, receiver := range receivers {

		err = funcs.SendEmail(*body, *subject, []string{receiver})
		if err != nil {
			funcs.PrintlnLog(fmt.Sprintf("sendmail.SendEmail.err: %v, receiver = %v", err, receiver))
		}
	}
}

// ticket submit mail
func getSubmitTypeTicketInfo(ticket model.Ticket, md metadataType) (*string, *string, []string, error) {
	receivers := make([]string, 0)
	receivers = append(receivers, getToList("submit", ticket)...)
	receivers = append(receivers, getCcList("submit", ticket)...)

	// get email title/content from db
	var emailTpl model.BaseEmailTemplates
	orm.Db.Table("openc3_tt_base_email_templates").Where("name='ticket_submit'").First(&emailTpl)

	// mail:subject
	subject, err := mergeEmailSubject(emailTpl.Title, md)
	if err != nil {
		return nil, nil, nil, err
	}
	// mail:body
	body, err := mergeEmailBody(emailTpl.Content, md)
	if err != nil {
		return nil, nil, nil, err
	}
	return &subject, &body, receivers, nil
}
func getUpdateTypeTicketInfo(ticket model.Ticket, md metadataType) (*string, *string, []string, error) {
	receivers := make([]string, 0)
	receivers = append(receivers, getToList("update", ticket)...)
	receivers = append(receivers, getCcList("update", ticket)...)

	// get email title/content from db
	var emailTpl model.BaseEmailTemplates
	orm.Db.Table("openc3_tt_base_email_templates").Where("name='ticket_update'").First(&emailTpl)

	// mail:subject
	subject, err := mergeEmailSubject(emailTpl.Title, md)
	if err != nil {
		return nil, nil, nil, err
	}
	// mail:body
	body, err := mergeEmailBody(emailTpl.Content, md)
	if err != nil {
		return nil, nil, nil, err
	}
	return &subject, &body, receivers, nil
}

// ticket update_reassign mail
func getReAssignTypeTicketInfo(ticket model.Ticket, md metadataType) (*string, *string, []string, error) {
	receivers := make([]string, 0)
	receivers = append(receivers, getToList("update_reassign", ticket)...)
	receivers = append(receivers, getCcList("update_reassign", ticket)...)

	// get email title/content from db
	var emailTpl model.BaseEmailTemplates
	orm.Db.Table("openc3_tt_base_email_templates").Where("name='ticket_update'").First(&emailTpl)

	// mail:subject
	subject, err := mergeEmailSubject(emailTpl.Title, md)
	if err != nil {
		return nil, nil, nil, err
	}
	// mail:body
	body, err := mergeEmailBody(emailTpl.Content, md)
	if err != nil {
		return nil, nil, nil, err
	}
	return &subject, &body, receivers, nil
}

// ticket update_solution mail
func getUpdateSolutionTypeTicketInfo(ticket model.Ticket, md metadataType) (*string, *string, []string, error) {
	receivers := make([]string, 0)
	receivers = append(receivers, getToList("update_solution", ticket)...)
	receivers = append(receivers, getCcList("update_solution", ticket)...)

	// get email title/content from db
	var emailTpl model.BaseEmailTemplates
	orm.Db.Table("openc3_tt_base_email_templates").Where("name='ticket_update_solution'").First(&emailTpl)

	// mail:subject
	subject, err := mergeEmailSubject(emailTpl.Title, md)
	if err != nil {
		return nil, nil, nil, err
	}
	// mail:body
	body, err := mergeEmailBody(emailTpl.Content, md)
	if err != nil {
		return nil, nil, nil, err
	}
	return &subject, &body, receivers, nil
}

// ticket add reply mail
func getAddReplyTypeTicketInfo(ticket model.Ticket, md metadataType) (*string, *string, []string, error) {
	receivers := make([]string, 0)
	receivers = append(receivers, getToList("add_reply", ticket)...)
	receivers = append(receivers, getCcList("add_reply", ticket)...)

	// get email title/content from db
	var emailTpl model.BaseEmailTemplates
	orm.Db.Table("openc3_tt_base_email_templates").Where("name='ticket_add_reply'").First(&emailTpl)

	// mail:subject
	subject, err := mergeEmailSubject(emailTpl.Title, md)
	if err != nil {
		return nil, nil, nil, err
	}
	// mail:body
	body, err := mergeEmailBody(emailTpl.Content, md)
	if err != nil {
		return nil, nil, nil, err
	}
	return &subject, &body, receivers, nil
}

// ticket add worklog mail
func getAddWorkLogTypeTicketInfo(ticket model.Ticket, md metadataType) (*string, *string, []string, error) {
	receivers := make([]string, 0)
	receivers = append(receivers, getToList("add_worklog", ticket)...)
	receivers = append(receivers, getCcList("add_worklog", ticket)...)

	// get email title/content from db
	var emailTpl model.BaseEmailTemplates
	orm.Db.Table("openc3_tt_base_email_templates").Where("name='ticket_add_worklog'").First(&emailTpl)

	// mail:subject
	subject, err := mergeEmailSubject(emailTpl.Title, md)
	if err != nil {
		return nil, nil, nil, err
	}
	// mail:body
	body, err := mergeEmailBody(emailTpl.Content, md)
	if err != nil {
		return nil, nil, nil, err
	}
	return &subject, &body, receivers, nil
}

// ticket timeout
func getTimeoutTypeTicketInfo(ticket model.Ticket, md metadataType) (*string, *string, []string, error) {
	receivers := make([]string, 0)
	receivers = append(receivers, getToList("timeout", ticket)...)
	receivers = append(receivers, getCcList("timeout", ticket)...)

	// get email title/content from db
	var emailTpl model.BaseEmailTemplates
	orm.Db.Table("openc3_tt_base_email_templates").Where("name='ticket_timeout'").First(&emailTpl)

	// mail:subject
	subject, err := mergeEmailSubject(emailTpl.Title, md)
	if err != nil {
		return nil, nil, nil, err
	}
	// mail:body
	body, err := mergeEmailBody(emailTpl.Content, md)
	if err != nil {
		return nil, nil, nil, err
	}
	return &subject, &body, receivers, nil
}

// ticket closed
func getCloseTypeTicketInfo(ticket model.Ticket, md metadataType) (*string, *string, []string, error) {
	receivers := make([]string, 0)
	receivers = append(receivers, getToList("closed", ticket)...)
	receivers = append(receivers, getCcList("closed", ticket)...)

	// get email title/content from db
	var emailTpl model.BaseEmailTemplates
	orm.Db.Table("openc3_tt_base_email_templates").Where("name='ticket_closed'").First(&emailTpl)

	// mail:subject
	subject, err := mergeEmailSubject(emailTpl.Title, md)
	if err != nil {
		return nil, nil, nil, err
	}
	// mail:body
	body, err := mergeEmailBody(emailTpl.Content, md)
	if err != nil {
		return nil, nil, nil, err
	}
	return &subject, &body, receivers, nil
}

/******************************************/

// 过滤邮箱地址
func filterEmailAddr(ori []string) []string {

	newArr := make([]string, 0)

	for _, email := range ori {
		if regexp.MustCompile("([\\w-\\.]+)@((?:[\\w]+\\.)+)([a-zA-Z]{2,4})").Match([]byte(email)) {
			newArr = append(newArr, email)
		}
	}

	return newArr
}

// 获取 to 收件人列表
func getToList(etype string, ticket model.Ticket) []string {

	var rcpt_to recipient
	send_to := make([]string, 0)

	if etype == "submit" || etype == "update" || etype == "update_reassign" || etype == "add_reply" || etype == "add_worklog" {
		orm.Db.Table("openc3_tt_base_group_user").Select("email users").Where("id = ?", ticket.GroupUser).Find(&rcpt_to)
		send_to = regexp.MustCompile("[;|,]").Split(strings.Replace(rcpt_to.Users, " ", "", -1), -1)
	}

	if etype == "update_solution" {
		orm.Db.Table("openc3_tt_base_group_user").Select("email users").Where("id = ?", ticket.GroupUser).Find(&rcpt_to)
		send_to = regexp.MustCompile("[;|,]").Split(strings.Replace(rcpt_to.Users, " ", "", -1), -1)
		send_to = append(send_to, ticket.SubmitUser, ticket.ApplyUser)
	}

	if etype == "closed" {
		send_to = append(send_to, ticket.SubmitUser, ticket.ApplyUser)
	}

	if etype == "timeout" {
		if ticket.Impact == 1 {
			orm.Db.Raw(fmt.Sprintf("select concat_ws(',', level1_report, group_email) users from openc3_tt_base_group where id=%d", ticket.Workgroup)).Scan(&rcpt_to)
		}
		if ticket.Impact == 2 {
			orm.Db.Raw(fmt.Sprintf("select concat_ws(',', level2_report, group_email) users from openc3_tt_base_group where id=%d", ticket.Workgroup)).Scan(&rcpt_to)
		}
		if ticket.Impact == 3 {
			orm.Db.Raw(fmt.Sprintf("select concat_ws(',', level3_report, group_email) users from openc3_tt_base_group where id=%d", ticket.Workgroup)).Scan(&rcpt_to)
		}
		if ticket.Impact == 4 {
			orm.Db.Raw(fmt.Sprintf("select concat_ws(',', level4_report, group_email) users from openc3_tt_base_group where id=%d", ticket.Workgroup)).Scan(&rcpt_to)
		}
		if ticket.Impact == 5 {
			orm.Db.Raw(fmt.Sprintf("select concat_ws(',', level5_report, group_email) users from openc3_tt_base_group where id=%d", ticket.Workgroup)).Scan(&rcpt_to)
		}
		send_to = regexp.MustCompile("[;|,]").Split(strings.Replace(rcpt_to.Users, " ", "", -1), -1)
	}

	fmt.Println("send to:", send_to)

	return send_to

}

// 获取 cc 列表
func getCcList(etype string, ticket model.Ticket) []string {

	var rcpt_cc recipient
	send_cc := make([]string, 0)

	if etype == "submit" || etype == "update" || etype == "add_reply" {
		orm.Db.Raw(fmt.Sprintf("select concat_ws(',', apply_user, email_list, group_email) users from (select apply_user, email_list, (select group_email from openc3_tt_base_group where id=workgroup) group_email from openc3_tt_ticket where id=%d) as a", ticket.ID)).Scan(&rcpt_cc)
		send_cc = regexp.MustCompile("[;|,]").Split(strings.Replace(rcpt_cc.Users, " ", "", -1), -1)
	}

	if etype == "update_reassign" {
		orm.Db.Raw(fmt.Sprintf("select concat_ws(',', apply_user, email_list, group_email) users from (select apply_user, email_list, (select group_email from openc3_tt_base_group where id=workgroup) group_email from openc3_tt_ticket where id=%d) as a", ticket.ID)).Scan(&rcpt_cc)
		send_cc = regexp.MustCompile("[;|,]").Split(strings.Replace(rcpt_cc.Users, " ", "", -1), -1)
	}
	if etype == "add_worklog" {
		orm.Db.Table("openc3_tt_base_group").Select("group_email users").Where("id = ?", ticket.Workgroup).Find(&rcpt_cc)
		send_cc = regexp.MustCompile("[;|,]").Split(strings.Replace(rcpt_cc.Users, " ", "", -1), -1)
	}
	if etype == "update_solution" || etype == "closed" {
		orm.Db.Raw(fmt.Sprintf("select concat_ws(',', email_list, group_email) users from (select email_list, (select group_email from openc3_tt_base_group where id=workgroup) group_email from openc3_tt_ticket where id=%d) as a", ticket.ID)).Scan(&rcpt_cc)
		send_cc = regexp.MustCompile("[;|,]").Split(strings.Replace(rcpt_cc.Users, " ", "", -1), -1)
	}
	if etype == "timeout" {
		orm.Db.Raw(fmt.Sprintf("select concat_ws(',', email, group_email) users from (select (select email from openc3_tt_base_group_user where id=group_user) email, (select group_email from openc3_tt_base_group where id=workgroup) group_email from openc3_tt_ticket where id=%d) as a", ticket.ID)).Scan(&rcpt_cc)
		send_cc = regexp.MustCompile("[;|,]").Split(strings.Replace(rcpt_cc.Users, " ", "", -1), -1)
	}

	fmt.Println("send cc:", send_cc)

	return send_cc
}

// merge email body(header->content->footer) 合并邮件内容
func mergeEmailBody(bodyContent string, md metadataType) (string, error) {

	// merge content
	//content := fmt.Sprintf("{{template \"header\"}}%s{{template \"footer\"}}", bodyContent)
	bodyParse := template.New("body")
	bodyT, err := bodyParse.Funcs(template.FuncMap{
		"html": func(value interface{}) template.HTML {
			return template.HTML(fmt.Sprint(value))
		},
		"timeformat": func(t time.Time) template.HTML {
			return template.HTML(t.Format("2006-01-02 15:04:05"))
		},
		"timeout": func(t bool) template.HTML {
			if t {
				return template.HTML("已超时")
			} else {
				return template.HTML("未超时")
			}
		},
		"emailparse": func(e string) template.HTML {
			return template.HTML(fmt.Sprintf("<a rel='nofollow' style='text-decoration:none;'>%s</a>", e))
		},
	}).Parse(bodyContent)
	fmt.Println("parse err:", err)
	if err != nil {
		return "", err
	}

	bodyBuf := new(bytes.Buffer)
	err = bodyT.Execute(bodyBuf, md)
	fmt.Println("execute:", err)
	if err != nil {
		return "", err
	}

	return bodyBuf.String(), nil

	// merge header/footer
	/**
	fullT, err := bodyT.Funcs(template.FuncMap{
		"email": func(e string) template.HTML {
			return template.HTML(fmt.Sprintf("<a rel='nofollow' style='text-decoration:none;color:#999'>%s</a>", e))
		},
	}).ParseFiles("./mail_tpls/header.html", "./mail_tpls/footer.html")
	if err != nil {
		return "", err
	}
	fullBuf := new(bytes.Buffer)
	err = fullT.Execute(fullBuf, md)
	if err != nil {
		return "", err
	}

	return fullBuf.String(), nil
	**/

}

// merge email subject 合并生成邮件标题
func mergeEmailSubject(title string, md metadataType) (string, error) {

	if config.Config().Debug {
		title = "[TEST] - " + title
	}

	titleParse := template.New("title")
	titleT, err := titleParse.Parse(title)
	if err != nil {
		return "", err
	}
	titleBuf := new(bytes.Buffer)
	err = titleT.Execute(titleBuf, md)
	if err != nil {
		return "", err
	}

	return titleBuf.String(), nil

}
