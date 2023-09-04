package handler

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"
	"sort"
	"strconv"
	"time"
)

// 根据时间戳范围查询有效的tt列表
//
// 如果工单已结束，使用解决时间进行筛选；如果工单未结束，则使用工单创建时间进行筛选
func getValidTicketList(startTimestamp, endTimestamp int64, searchKeyword string) []STicket {
	startTime := time.Unix(startTimestamp, 0)
	endTime := time.Unix(endTimestamp, 0)

	var tickets []STicket

	query := orm.Db.Table("openc3_tt_ticket").
		Where(`
        (CASE 
            WHEN resolve_time IS NOT NULL THEN resolve_time 
            ELSE created_at 
        END) BETWEEN ? AND ?`, startTime, endTime)

	if searchKeyword != "" {
		query = query.Where("title LIKE ? OR content LIKE ? OR no = ?",
			"%"+searchKeyword+"%",
			"%"+searchKeyword+"%",
			searchKeyword)
	}

	query.Find(&tickets)

	return GetTicketsRemain(tickets)
}

func getUserGroupIdsMap(userAccount string) map[int64]struct{} {
	groupUsers := make([]model.BaseGroupUser, 0)
	orm.Db.Table("openc3_tt_base_group_user").Where("email = ?", userAccount).Find(&groupUsers)

	data := make(map[int64]struct{})

	for _, item := range groupUsers {
		data[item.GroupId] = struct{}{}
	}

	return data
}

type pair struct {
	Key   string `json:"key"`
	Value int    `json:"value"`
}

func sortAndGetTenItems(data map[string]int) []pair {
	var pairs []pair
	for k, v := range data {
		pairs = append(pairs, pair{k, v})
	}

	// 按照提工单数排序，最后只返回前10条数据
	sort.Slice(pairs, func(i, j int) bool {
		return pairs[i].Value > pairs[j].Value
	})

	result := make([]pair, 0)
	for _, p := range pairs {
		if p.Key == "" {
			continue
		}
		if len(result) >= 10 {
			break
		}

		result = append(result, p)
	}

	return result
}

// 根据输入的tt列表获取所有的申请人
func getUserList(ticketList []STicket) []string {
	data := make(map[string]struct{})
	for _, item := range ticketList {
		if item.ApplyUser == "" {
			continue
		}
		data[item.ApplyUser] = struct{}{}
	}

	result := make([]string, 0)

	for item, _ := range data {
		result = append(result, item)
	}
	return result
}

// 获取个人代码tt还是组待办tt
func getTodoTicketList(ticketList []STicket, account string, all string) []STicket {
	result := make([]STicket, 0)

	groupIdsMap := getUserGroupIdsMap(account)

	for _, item := range ticketList {
		if all == "0" {
			var groupUser model.BaseGroupUser
			orm.Db.Table("openc3_tt_base_group_user").Where("id = ?", item.GroupUser).Find(&groupUser)
			if groupUser.Email == account {
				result = append(result, item)
			}
		} else {
			if _, ok := groupIdsMap[item.Workgroup]; ok {
				result = append(result, item)
			}
		}
	}
	return result
}

// GetUserAccounts 获取用户列表
//
// @Summary 获取所有运维人员预配置
// @Description 获取所有运维人员预配置
// @Tags tt统计
// @Accept json
// @Param start path int true "起始时间戳. 秒数"
// @Param end path int true "结束时间戳. 秒数"
// @Success 200 {array} string
// @Router /statistics/get_user_accounts [get]
func GetUserAccounts(c *gin.Context) {
	start := c.Query("start")
	end := c.Query("end")

	startTimestamp, err := strconv.ParseInt(start, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("start格式错误"))
		return
	}
	endTimestamp, err := strconv.ParseInt(end, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("end格式错误"))
		return
	}

	ticketList := getValidTicketList(startTimestamp, endTimestamp, "")

	result := getUserList(ticketList)

	c.JSON(http.StatusOK, status_200(result))
}

// GetTickets 获取tt列表
//
// @Summary 获取tt列表
// @Description 获取tt列表
// @Tags tt统计
// @Accept json
// @Param start path int true "起始时间戳. 秒数"
// @Param end path int true "结束时间戳. 秒数"
// @Param keyword path string false "搜索关键字"
// @Success 200 {array} model.Ticket
// @Router /statistics/get_tts [get]
func GetTickets(c *gin.Context) {
	start := c.Query("start")
	end := c.Query("end")
	keyword := c.Query("keyword")

	startTimestamp, err := strconv.ParseInt(start, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("start格式错误"))
		return
	}
	endTimestamp, err := strconv.ParseInt(end, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("end格式错误"))
		return
	}

	ticketList := getValidTicketList(startTimestamp, endTimestamp, keyword)

	c.JSON(http.StatusOK, status_200(ticketList))
}

// GetTodoTickets 获取待办tt列表
//
// @Summary 获取待办tt列表
// @Description 获取待办tt列表
// @Tags tt统计
// @Accept json
// @Param start query int true "起始时间戳. 秒数"
// @Param end query int true "结束时间戳. 秒数"
// @Param all query int true "是否获取所有待办. 1: 获取所有待办;  0: 获取个人待办"
// @Param keyword path string false "搜索关键字"
// @Success 200 {array} model.Ticket
// @Router /statistics/get_todo_tts [get]
func GetTodoTickets(c *gin.Context) {
	start := c.Query("start")
	end := c.Query("end")
	all := c.Query("all")
	keyword := c.Query("keyword")

	if start == "" || end == "" || all == "" {
		c.JSON(http.StatusOK, status_400("缺少必填参数"))
		return
	}

	startTimestamp, err := strconv.ParseInt(start, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("start格式错误"))
		return
	}
	endTimestamp, err := strconv.ParseInt(end, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("end格式错误"))
		return
	}

	ticketList := getValidTicketList(startTimestamp, endTimestamp, keyword)

	oaUser, _ := c.Get("oauser")
	account := oaUser.(string)

	result := getTodoTicketList(ticketList, account, all)

	c.JSON(http.StatusOK, status_200(result))
}

// GetWorkOrderSummary 获取工单按类别统计
//
// @Summary 获取工单按类别统计
// @Description 获取工单按类别统计
// @Tags tt统计
// @Accept json
// @Param start query int true "起始时间戳. 秒数"
// @Param end query int true "结束时间戳. 秒数"
// @Router /statistics/work_order_summary [get]
func GetWorkOrderSummary(c *gin.Context) {
	start := c.Query("start")
	end := c.Query("end")

	if start == "" || end == "" {
		c.JSON(http.StatusOK, status_400("缺少必填参数"))
		return
	}

	startTimestamp, err := strconv.ParseInt(start, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("start格式错误"))
		return
	}
	endTimestamp, err := strconv.ParseInt(end, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("end格式错误"))
		return
	}

	ticketList := getValidTicketList(startTimestamp, endTimestamp, "")

	data := make(map[string]map[string]int)

	nameMap := make(map[int64]string)

	allKeys := make(map[string]struct{})
	for _, item := range ticketList {
		var t time.Time
		if !item.ResolveTime.IsZero() {
			t = item.ResolveTime
		} else {
			t = item.CreatedAt
		}
		timeStr := t.Format("2006-01-02")

		if _, ok := data[timeStr]; !ok {
			data[timeStr] = make(map[string]int)
		}

		if _, ok := nameMap[item.Type]; !ok {
			var baseType model.BaseType
			orm.Db.Table("openc3_tt_base_type").Where("id = ?", item.Type).Find(&baseType)

			nameMap[item.Type] = baseType.Name
		}

		typeName := nameMap[item.Type]

		allKeys[typeName] = struct{}{}

		data[timeStr][typeName] = data[timeStr][typeName] + 1
	}

	type itemType struct {
		Date string         `json:"date"`
		Data map[string]int `json:"data"`
	}

	result := make([]itemType, 0)

	for timeStr, value := range data {
		item := itemType{
			Date: timeStr,
			Data: make(map[string]int),
		}
		for key, _ := range allKeys {
			if count, ok := value[key]; ok {
				item.Data[key] = count
			} else {
				item.Data[key] = 0
			}
		}

		result = append(result, item)
	}

	c.JSON(http.StatusOK, status_200(result))
}

// GetWorkOrderByApplyUserSummary 获取工单按申请人统计(只返回前10)
//
// @Summary 获取工单按申请人统计(只返回前10)
// @Description 获取工单按申请人统计(只返回前10)
// @Tags tt统计
// @Accept json
// @Param start query int true "起始时间戳. 秒数"
// @Param end query int true "结束时间戳. 秒数"
// @Router /statistics/work_order_summary/by_apply_user [get]
func GetWorkOrderByApplyUserSummary(c *gin.Context) {
	start := c.Query("start")
	end := c.Query("end")

	if start == "" || end == "" {
		c.JSON(http.StatusOK, status_400("缺少必填参数"))
		return
	}

	startTimestamp, err := strconv.ParseInt(start, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("start格式错误"))
		return
	}
	endTimestamp, err := strconv.ParseInt(end, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("end格式错误"))
		return
	}

	ticketList := getValidTicketList(startTimestamp, endTimestamp, "")

	data := make(map[string]int)

	for _, item := range ticketList {
		data[item.ApplyUser] = data[item.ApplyUser] + 1
	}

	result := sortAndGetTenItems(data)

	c.JSON(http.StatusOK, status_200(result))
}

// GetWorkOrderByStatusSummary 获取工单按 待办/完成 统计(只返回前10)
//
// @Summary 获取工单按 待办/完成 统计(只返回前10)
// @Description 获取工单按 待办/完成 统计(只返回前10)
// @Tags tt统计
// @Accept json
// @Param start query int true "起始时间戳. 秒数"
// @Param end query int true "结束时间戳. 秒数"
// @Param status query int true "是否结束。1: 完成的工单; 0: 未完成工单"
// @Router /statistics/work_order_summary/by_status [get]
func GetWorkOrderByStatusSummary(c *gin.Context) {
	start := c.Query("start")
	end := c.Query("end")
	status := c.Query("status")

	if start == "" || end == "" || status == "" {
		c.JSON(http.StatusOK, status_400("缺少必填参数"))
		return
	}

	startTimestamp, err := strconv.ParseInt(start, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("start格式错误"))
		return
	}
	endTimestamp, err := strconv.ParseInt(end, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("end格式错误"))
		return
	}

	ticketList := getValidTicketList(startTimestamp, endTimestamp, "")

	data := make(map[int64]int)

	for _, item := range ticketList {
		if status == "1" {
			if !item.ResolveTime.IsZero() {
				data[item.GroupUser] = data[item.GroupUser] + 1
			}
		} else {
			if item.ResolveTime.IsZero() {
				data[item.GroupUser] = data[item.GroupUser] + 1
			}
		}
	}

	data1 := make(map[string]int)
	for groupUserId, count := range data {
		var groupUser model.BaseGroupUser
		orm.Db.Table("openc3_tt_base_group_user").Where("id = ?", groupUserId).Find(&groupUser)

		data1[groupUser.Email] = count
	}

	result := sortAndGetTenItems(data1)

	c.JSON(http.StatusOK, status_200(result))
}

type Summary struct {
	// 用户总数
	UserCount int `json:"user_count"`
	// 工单总数
	TtCount int `json:"tt_count"`
	// 个人待办总数
	SelfTodoCount int `json:"self_todo_count"`
	// 待办总数
	RelatedGroupTotoCount int `json:"related_group_toto_count"`
}

// GetStatisticsSummary 获取简要的统计信息。目前只包含了用户总数、工单总数、待办总数、个人待办总数
//
// @Summary 获取简要的统计信息。目前只包含了用户总数、工单总数、待办总数、个人待办总数
// @Description 获取简要的统计信息。目前只包含了用户总数、工单总数、待办总数、个人待办总数
// @Tags tt统计
// @Accept json
// @Param start query int true "起始时间戳. 秒数"
// @Param end query int true "结束时间戳. 秒数"
// @Success 200 {object} Summary
// @Router /statistics/work_order_summary/summary [get]
func GetStatisticsSummary(c *gin.Context) {
	start := c.Query("start")
	end := c.Query("end")

	if start == "" || end == "" {
		c.JSON(http.StatusOK, status_400("缺少必填参数"))
		return
	}

	startTimestamp, err := strconv.ParseInt(start, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("start格式错误"))
		return
	}
	endTimestamp, err := strconv.ParseInt(end, 10, 64)
	if err != nil {
		c.JSON(http.StatusOK, status_400("end格式错误"))
		return
	}

	oaUser, _ := c.Get("oauser")
	account := oaUser.(string)

	ticketList := getValidTicketList(startTimestamp, endTimestamp, "")

	userList := getUserList(ticketList)
	selfTodoList := getTodoTicketList(ticketList, account, "0")
	relatedGroupTotoList := getTodoTicketList(ticketList, account, "1")

	s := Summary{
		UserCount:             len(userList),
		TtCount:               len(ticketList),
		SelfTodoCount:         len(selfTodoList),
		RelatedGroupTotoCount: len(relatedGroupTotoList),
	}

	c.JSON(http.StatusOK, status_200(s))
}
