package handler

import (
	"fmt"
	"net/http"
	"reflect"
	"strconv"
	"time"

	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"

	"github.com/gin-gonic/gin"
)

type ReportStruct struct {
	ID                       int64  `json:"id"`
	SubmitNumber             int64  `json:"submit_number"`                // 提交单子数量
	ResponseNumber           int64  `json:"response_number"`              // 响应数量
	ResolveNumber            int64  `json:"resolve_number"`               // 解决数量
	ResponseTimeoutNumber    int64  `json:"response_timeout_number"`      // 响应超时数量
	ResolveTimeoutNumber     int64  `json:"resolve_timeout_number"`       // 解决超时数量
	TotalResponseTime        int64  `json:"total_response_time"`          // 总响应时间
	TotalResolveTime         int64  `json:"total_resolve_time"`           // 总解决时间
	MeanReponseTime          int64  `json:"mean_response_time"`           // 平均相应时间
	MeanResolveTime          int64  `json:"mean_resolve_time"`            // 平均解决时间
	NoneOneTimeResolveNumber int64  `json:"none_one_time_resolve_number"` // 非一次解决数量
	ResponseTimeRate         string `json:"response_timeout_rate"`        // 响应超时率
	ResolveTimeRate          string `json:"resolve_timeout_rate"`         // 解决超时率
	ResolveRate              string `json:"resolve_rate"`                 // 解决率
	OneTimeResolveRate       string `json:"one_time_resolve_rate"`        // 一次解决率
}

// 报表-工作组看板/CTI看板
func ReportKanban(c *gin.Context) {

	type ReqStruct struct {
		Start time.Time `json:"start" binding:"required"`
		End   time.Time `json:"end" binding:"required"`
	}

	var req ReqStruct
	tickets := make([]model.Ticket, 0)

	if c.BindJSON(&req) == nil {

		start := req.Start.Local().Format("2006-01-02")
		end := req.End.Local().AddDate(0, 0, 1).Format("2006-01-02")

		if err := orm.Db.Table("openc3_tt_ticket").Select("group_user, item, status, workgroup, response_time, response_cost, response_timeout_sent, resolve_time, resolve_cost, resolve_timeout_sent, one_time_resolve_rate, created_at").Where("created_at < ?", end).Where("created_at >= ?", start).Find(&tickets).Error; err != nil {
			c.JSON(http.StatusOK, status_400(err))
			return
		}
		// 计算
		reportWG := calcute_metrics(tickets, "Workgroup")
		reportCTI := calcute_metrics(tickets, "Item")

		if err := orm.Db.Table("openc3_tt_ticket").Select("group_user, item, status, workgroup, response_time, response_cost, response_timeout_sent, resolve_time, resolve_cost, resolve_timeout_sent, one_time_resolve_rate, created_at").Where("created_at < ?", end).Where("created_at >= ?", start).Where("group_user is not null ").Find(&tickets).Error; err != nil {
			c.JSON(http.StatusOK, status_400(err))
			return
		}
		reportGroupUser := calcute_metrics(tickets,	"GroupUser")

		report := map[string][]*ReportStruct{
			"workgroup": 	reportWG,
			"cti":       	reportCTI,
			"group_user":	reportGroupUser,
		}

		c.JSON(http.StatusOK, status_200(report))

	}

}

// 计算指标

func calcute_metrics(tickets []model.Ticket, key string) []*ReportStruct {

	res := make(map[string]*ReportStruct)
	res["0"] = new(ReportStruct)

	for _, ticket := range tickets {

		k := strconv.FormatInt(reflect.ValueOf(ticket).FieldByName(key).Int(), 10)

		if res[k] == nil {
			res[k] = new(ReportStruct)
		}

		res[k].SubmitNumber += 1
		res[k].ID, _ = strconv.ParseInt(k, 10, 64)
		res["0"].SubmitNumber += 1
		res["0"].ID = 0

		// 响应数量 响应总时间
		if !ticket.ResponseTime.IsZero() {
			res[k].TotalResponseTime += ticket.ResponseCost
			res[k].ResponseNumber += 1
			res["0"].TotalResponseTime += ticket.ResponseCost
			res["0"].ResponseNumber += 1
		}
		// 解决数量 解决总时间
		if ticket.Status == "resolved" || ticket.Status == "closed" {
			res[k].ResolveNumber += 1
			res[k].TotalResolveTime += ticket.ResolveCost
			res["0"].ResolveNumber += 1
			res["0"].TotalResolveTime += ticket.ResolveCost
		}
		// 响应超时数量
		if ticket.ResponseTimeoutSent > 0 {
			res[k].ResponseTimeoutNumber += 1
			res["0"].ResponseTimeoutNumber += 1
		}
		// 解决超时数量
		if ticket.ResolveTimeoutSent > 0 {
			res[k].ResolveTimeoutNumber += 1
			res["0"].ResolveTimeoutNumber += 1
		}

		// 非一次解决数量
		if ticket.OneTimeResolveRate != 0 {
			res[k].NoneOneTimeResolveNumber += 1
			res["0"].NoneOneTimeResolveNumber += 1
		}

	}

	for k, v := range res {

		// 计算平均响应时间
		if v.ResponseNumber != 0 {
			res[k].MeanReponseTime = v.TotalResponseTime / v.ResponseNumber
		} else {
			res[k].MeanReponseTime = v.TotalResponseTime / 1
		}

		// 计算平均解决时间
		if v.ResolveNumber != 0 {
			res[k].MeanResolveTime = v.TotalResolveTime / v.ResolveNumber
		} else {
			res[k].MeanResolveTime = v.TotalResolveTime / 1
		}

		// 计算解决率
		res[k].ResolveRate = fmt.Sprintf("%.2f%%", float64(v.ResolveNumber)/float64(v.SubmitNumber)*100)

		// 计算一次解决率
		if v.ResolveNumber != 0 {
			res[k].OneTimeResolveRate = fmt.Sprintf("%.2f%%", float64((v.ResolveNumber-v.NoneOneTimeResolveNumber))/float64(v.ResolveNumber)*100)
		} else {
			res[k].OneTimeResolveRate = "0.00%"
		}

		// 计算响应超时率
		res[k].ResponseTimeRate = fmt.Sprintf("%.2f%%", float64(v.ResponseTimeoutNumber)/float64(v.SubmitNumber)*100)

		// 计算解决超时率
		res[k].ResolveTimeRate = fmt.Sprintf("%.2f%%", float64(v.ResolveTimeoutNumber)/float64(v.SubmitNumber)*100)

	}

	// obj -> arr
	arr := make([]*ReportStruct, 0)
	for _, v := range res {
		arr = append(arr, v)
	}

	return arr
}
