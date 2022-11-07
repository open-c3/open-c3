package handler

import (
	"time"

	"openc3.org/trouble-ticketing/config"
	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"
)

// 检测sla超时
func CronSLACheck() {

	for {
		// all impact
		impacts := make([]model.BaseImpact, 0)
		orm.Db.Find(&impacts)
		// all group
		groups := make([]model.BaseGroup, 0)
		orm.Db.Find(&groups)
		//获取所有 非closed 状态的ticket
		tickets := make([]model.Ticket, 0)
		orm.Db.Where("status!='closed' and (response_timeout_sent=0 || resolve_timeout_sent=0)").Find(&tickets)
		for _, t := range tickets {

			var impact model.BaseImpact
			var group model.BaseGroup
			for _, i := range impacts {
				if i.ID == t.Impact {
					impact = i
				}
			}
			for _, g := range groups {
				if g.ID == t.Workgroup {
					group = g
				}
			}

			// check sla
			responseDeadline, resolveDeadline, responseTimeout, resolveTimeout := CalTicketDeadline(impact, group, t)

			needsend := false
			if responseTimeout && t.ResponseTimeoutSent == 0 {
				t.ResponseTimeoutSent = 1
				needsend = true
			}
			if resolveTimeout && t.ResolveTimeoutSent == 0 {
				t.ResolveTimeoutSent = 1
				needsend = true
			}
			if needsend {
				db := orm.Db.Table("openc3_tt_ticket").Where("id = ?", t.ID).Updates(t)
				if err := db.Error; err != nil {
					return
				}
				// -> send email
				if db.RowsAffected > 0 {
					go sendmail("", "ticket_timeout", t.ID, nil, responseDeadline, resolveDeadline, responseTimeout, resolveTimeout)
				}
			}
		}

		time.Sleep(time.Second * 20)
	}

}

// 自动close事件
func CronCloseTicket() {

	// 7 day
	timeDuration := time.Hour * 24 * 7
	if config.Config().Debug {
		timeDuration = time.Hour * 1
	}

	for {

		now := time.Now()

		// all group
		groups := make([]model.BaseGroup, 0)
		orm.Db.Find(&groups)

		//获取所有 resolved 状态的ticket
		tickets := make([]model.Ticket, 0)
		orm.Db.Where("status='resolved'").Find(&tickets)

		for _, t := range tickets {

			if t.ResolveTime.IsZero() {
				continue
			}

			if t.ResponseTime.IsZero() {
				t.ResponseTime = t.ResolveTime
			}

			// if timeout -> closed
			if now.After(t.ResolveTime.Add(timeDuration)) {

				var group model.BaseGroup
				for _, g := range groups {
					if g.ID == t.Workgroup {
						group = g
						break
					}
				}
				if group.ID == 0 {
					continue
				}

				// cal response/resolve cost
				t.ResponseCost = CalWorktimeCost(t.CreatedAt, t.ResponseTime, group)
				t.ResolveCost = CalWorktimeCost(t.CreatedAt, t.ResolveTime, group)

				// one-time resolve rate
				syslogs := make([]model.CommonSysLog, 0)
				orm.Db.Where("oper_column='status' and oper_pre='resolved' and oper_after!='closed' and ticket_id=?", t.ID).Find(&syslogs)
				t.OneTimeResolveRate = int64(len(syslogs))

				// change status -> closed
				t.Status = "closed"
				t.ClosedTime = now
				db := orm.Db.Table("openc3_tt_ticket").Where("id = ?", t.ID).Updates(t)
				if err := db.Error; err != nil {
					return
				}

				// -> send email
				if db.RowsAffected > 0 {
					// syslog
					var syslog model.CommonSysLog
					syslog.OperType = "update"
					syslog.OperUser = "system"
					syslog.OperColumn = "status"
					syslog.OperPre = "resolved"
					syslog.OperAfter = "closed"
					syslog.TicketId = t.ID
					orm.Db.Create(&syslog)
					//关闭状态不发送邮件
					//go sendmail("", "ticket_closed", t.ID, nil)
				}
			}
		}

		time.Sleep(time.Minute)

	}

}
