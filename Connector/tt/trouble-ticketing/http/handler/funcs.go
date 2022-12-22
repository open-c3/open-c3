package handler

import (
	"strconv"
	"strings"
	"time"

	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"

	"github.com/gin-gonic/gin"
)

// 200
func status_200(data interface{}) gin.H {
	return gin.H{
		"code": 200,
		"msg":  "ok",
		"data": data,
	}
}

func status_200_v2(data interface{}) gin.H {
	return gin.H{
		"stat": 1,
		"data": data,
	}
}

// 400
func status_400(data interface{}) gin.H {
	return gin.H{
		"code": 400,
		"msg":  "bad request",
		"data": data,
	}
}

func status_400_v2(info interface{}) gin.H {
	return gin.H{
		"stat": 0,
		"info": info,
	}
}

// 403
func status_403(data interface{}) gin.H {
	return gin.H{
		"code": 403,
		"msg":  "forbidden",
		"data": data,
	}
}

// 404
func status_404(data interface{}) gin.H {
	return gin.H{
		"code": 404,
		"msg":  "not found",
		"data": data,
	}
}

/********************************************/
// SLA
/********************************************/

// 批量获取tickets的 deadline/timeout
func GetTicketsRemain(tickets []STicket) []STicket {

	// get groups
	workgroups := make([]model.BaseGroup, 0)
	orm.Db.Find(&workgroups)

	// get impacts
	impacts := make([]model.BaseImpact, 0)
	orm.Db.Find(&impacts)

	for k, t := range tickets {
		var group model.BaseGroup
		var impact model.BaseImpact
		for _, g := range workgroups {
			if g.ID == t.Workgroup {
				group = g
				break
			}
		}
		for _, i := range impacts {
			if i.ID == t.Impact {
				impact = i
				break
			}
		}
		//tickets[k].ResponseRemain, tickets[k].ResolveRemain = CheckTicketSlaRemain(impact, group, t.Ticket)
		tickets[k].ResponseDeadline, tickets[k].ResolveDeadline, tickets[k].ResponseTimeout, tickets[k].ResolveTimeout = CalTicketDeadline(impact, group, t.Ticket)
	}

	return tickets
}

// 检测某个ticket的response/resolve 剩余时间sec
// 根据ticket所在impact（总时间）以及workgroup（工作时间)
/**
func CheckTicketSlaRemain(impact model.BaseImpact, workgroup model.BaseGroup, t model.Ticket) (int64, int64) {

	now := time.Now()

	// response
	response_total_sec := impact.ResponseSLA * 60
	response_cost_sec := t.ResponseCost
	if t.ResponseTime.IsZero() {
		response_cost_sec = CalWorktimeCost(t.CreatedAt, now, workgroup)
	}

	// resolve
	resolve_total_sec := impact.ResolveSLA * 60
	resolve_cost_sec := t.ResolveCost
	if !(t.Status == "resolved") && !(t.Status == "closed") {
		resolve_cost_sec = CalWorktimeCost(t.ResolveStart, now, workgroup) + t.ResolveCost
	}

	return response_total_sec - response_cost_sec, resolve_total_sec - resolve_cost_sec
}
**/

// 计算某个工作组workgroup 从start到end 期间的工作时长(s)
func CalWorktimeCost(start, end time.Time, workgroup model.BaseGroup) int64 {

	if start.IsZero() || end.IsZero() {
		return int64(0)
	}

	// change timezone time
	start_tz := start.Add((time.Duration)(-8+workgroup.Timezone) * time.Hour)
	end_tz := end.Add((time.Duration)(-8+workgroup.Timezone) * time.Hour)

	// end-start 段，每个分钟检测
	loopStart := start_tz
	worktime_count := 0
	for {
		if end_tz.Before(loopStart) {
			break
		}
		if CheckIfWorktime(loopStart, workgroup) {
			worktime_count++
		}
		loopStart = loopStart.Add(time.Minute)
	}
	start_second := start_tz.Second()
	end_second := end_tz.Second()
	if !CheckIfWorktime(start_tz, workgroup) {
		start_second = 0
	}
	if !CheckIfWorktime(end_tz, workgroup) {
		end_second = 0
	}

	if worktime_count > 0 {
		if end_second >= start_second {
			worktime_count--
		}
	}

	total := worktime_count*60 + end_second - start_second

	return int64(total)

}

// 检测某一时刻t是否是workgroup的工作时间
func CheckIfWorktime(t time.Time, workgroup model.BaseGroup) bool {

	workdayArr := strings.Split(workgroup.WorkDay, ",")
	workhour_start := workgroup.WorkHourStart
	workhour_end := workgroup.WorkHourEnd

	// 工作日检测
	weekday := t.Weekday()
	isWorkday := contains(int64(weekday), workdayArr)
	if !isWorkday {
		return false
	}

	// 工作时间检测
	thisMoment := int64(t.Hour()*60 + t.Minute())
	if thisMoment >= workhour_start && thisMoment < workhour_end {
		return true
	}

	return false
}

// day 是否在arr的工作日
func contains(day int64, arr []string) bool {
	for _, a := range arr {
		inta, _ := strconv.ParseInt(a, 10, 64)
		if inta == day {
			return true
		}
	}
	return false
}

/**********************************/

// 计算某个ticket response/resolve deadline, 是否超时
func CalTicketDeadline(impact model.BaseImpact, workgroup model.BaseGroup, t model.Ticket) (time.Time, time.Time, bool, bool) {

	now := time.Now()

	/** response **/
	// deadline
	response_total_mins := impact.ResponseSLA
	response_deadline := t.CreatedAt
	if !CheckIfWorktime(response_deadline, workgroup) {
		response_deadline = response_deadline.Add(-1 * time.Second * time.Duration(response_deadline.Second()))
	}
	for {
		if CheckIfWorktime(response_deadline, workgroup) {
			response_total_mins--
			if response_total_mins < 0 {
				break
			}
		}
		response_deadline = response_deadline.Add(time.Minute)
	}
	// timeout
	response_timeout := false
	if t.ResponseTime.IsZero() {
		if now.After(response_deadline) {
			response_timeout = true
		}
	} else {
		if t.ResponseTime.After(response_deadline) {
			response_timeout = true
		}
	}

	/** resolve **/
	// deadline
	resolve_total_mins := impact.ResolveSLA
	resolve_deadline := t.CreatedAt
	if !CheckIfWorktime(resolve_deadline, workgroup) {
		resolve_deadline = resolve_deadline.Add(-1 * time.Second * time.Duration(resolve_deadline.Second()))
	}

	for {
		if CheckIfWorktime(resolve_deadline, workgroup) {
			resolve_total_mins--
			if resolve_total_mins < 0 {
				break
			}
		}
		resolve_deadline = resolve_deadline.Add(time.Minute)
	}
	// timeout
	resolve_timeout := false
	if t.Status == "resolved" || t.Status == "closed" {
		if t.ResolveTime.After(resolve_deadline) {
			resolve_timeout = true
		}
	} else {
		if now.After(resolve_deadline) {
			resolve_timeout = true
		}
	}

	return response_deadline, resolve_deadline, response_timeout, resolve_timeout

}

// 计算某个ticket的解决天数resolvedays（消耗工作日）
func CalTicketResolveDays(t model.Ticket, workgroup model.BaseGroup) int64 {

	var days int64
	workdayArr := strings.Split(workgroup.WorkDay, ",")
	start := t.CreatedAt
	end := time.Now()
	// 用于处理手工关闭工单的情况
	ok := false

	if t.Status == "resolved" || t.Status == "closed" {
		end = t.ResolveTime
		if t.ResolveTime.Unix() > 0 {
			ok = true
		}
	}

	if ok {
		currentWeekday := start.Weekday()
		for {
			if start.Year() == end.Year() && start.Month() == end.Month() && start.Day() == end.Day() {
				break
			}
			start = start.Add(time.Hour)
			if start.Weekday() != currentWeekday && contains(int64(start.Weekday()), workdayArr) {
				days++
				currentWeekday = start.Weekday()
			}
		}
	}

	return days
}

// 检测CTI所属关系是否正确
func CheckCTIRelation(C, T, I int64) bool {

	if C <= 0 || T <= 0 || I <= 0 {
		return false
	}

	var category model.BaseCategory
	orm.Db.Where("id = ?", C).First(&category)

	var typ model.BaseType
	orm.Db.Where("id = ?", T).First(&typ)

	var item model.BaseItem
	orm.Db.Where("id = ?", I).First(&item)

	if item.TypeId != T || typ.CategoryId != C {
		return false
	}

	return true
}

// 检测工作组／组员　所属关系是否正确
func CheckGroupUserRelation(g, u int64) bool {
	if u == 0 {
		return true
	}

	if g == 0 {
		return false
	}

	var user model.BaseGroupUser
	orm.Db.Where("id = ?", u).First(&user)

	if user.GroupId == g {
		return true
	}

	return false
}
