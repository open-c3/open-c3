package handler

import (
	"fmt"
	"net/http"
	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/util"
	"os"
	"os/exec"
	"strings"

	"github.com/gin-gonic/gin"
	"openc3.org/trouble-ticketing/config"
	"openc3.org/trouble-ticketing/orm"
)

// PublicPostTicket 第三方系统添加事件
func PublicPostTicket(c *gin.Context) {
	type reqT struct {
		Title     string `json:"title" binding:"required"`
		Content   string `json:"content" binding:"required"`
		EmailList string `json:"email_list"`

		Impact int64 `json:"impact"`
		C      int64 `json:"c"`
		T      int64 `json:"t"`
		I      int64 `json:"i"`

		SubmitUser string `json:"submit_user"`
		ApplyUser  string `json:"apply_user"`
	}

	var req reqT

	err := c.BindJSON(&req)
	if err != nil {
		c.JSON(http.StatusOK, status_400_v2(err.Error()))
		return
	}
	var (
		obj         ticket
		workGroupId *int64
		groupUserId *int64
	)
	workGroupId, groupUserId = findGroupIdAndUserId(req.Title)
	if workGroupId == nil {
		c.JSON(http.StatusOK, status_400_v2("没有找到默认的组和处理用户, 工单名称: "+req.Title))
		return
	}

	if strings.TrimSpace(req.ApplyUser) == "" {
		c.JSON(http.StatusOK, status_400_v2("apply user reqiured"))
		return
	}

	obj.ApplyUser = req.ApplyUser
	obj.Impact = req.Impact
	obj.Category = req.C
	obj.Type = req.T
	obj.Item = req.I
	obj.Workgroup = *workGroupId
	obj.GroupUser = *groupUserId
	obj.Title = req.Title
	obj.Content = req.Content
	obj.EmailList = req.EmailList
	obj.SubmitUser = req.SubmitUser
	obj.ApplyUser = req.ApplyUser

	err = orm.Db.Create(&obj).Error
	if err != nil {
		c.JSON(http.StatusOK, status_400_v2(err.Error()))
		return
	}
	c.JSON(http.StatusOK, status_200_v2(obj.No))
}

func findGroupIdAndUserId(title string) (*int64, *int64) {
	var (
		workGroupId, groupUserId *int64
		found                    bool
		err                      error
	)

	for _, workflowConfig := range config.Config().WorkflowList {
		for _, keyword := range workflowConfig.KeywordList {
			if strings.Contains(title, keyword) || keyword == "*" {
				found = true
				break
			}
		}
		if !found {
			continue
		}

		var (
			group model.BaseGroup
			user  model.BaseGroupUser
		)

		workGroupId, err = getValue(workflowConfig.WorkGroupId, &group, "group_name")
		if err != nil {
			fmt.Fprintf(os.Stderr, "findGroupIdAndUserId.getValue.group_name.err: %v", err)
			return nil, nil
		}
		groupUserId, err = getValue(workflowConfig.GroupUserId, &user, "email")
		if err != nil {
			fmt.Fprintf(os.Stderr, "findGroupIdAndUserId.getValue.name.err: %v", err)
			return nil, nil
		}
		if found {
			return workGroupId, groupUserId
		}
	}
	return nil, nil
}

func getValue(i interface{}, tableRecord interface{}, fieldName string) (*int64, error) {
	var (
		value int64
	)
	switch v := i.(type) {
	case float64:
		value = int64(v)
	case string:
		b, err := exec.Command("c3mc-sys-ctl", v).Output()
		if err != nil {
			return nil, fmt.Errorf("从系统参数获取默认组或用户时出错, 错误信息为: %v", err)
		}
		sysEnvValue := strings.TrimRight(string(b), "\n")
		if orm.Db.Where(fmt.Sprintf("%v = ?", fieldName), sysEnvValue).First(tableRecord).RecordNotFound() {
			return nil, fmt.Errorf("从数据库查找组或者用户时未找到相关记录, 名称: %v", sysEnvValue)
		}

		m := util.ConvertStructInterToMap(tableRecord)
		value = m["ID"].(int64)
	default:
		return nil, nil
	}
	return &value, nil
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

// 获取事件基础信息
func PublicGetTicketInfo(c *gin.Context) {
	type ticket struct {
		ID           int64  `json:"id"`
		No           string `json:"no"`
		Status       string `json:"status"`
		ResponseCost int64  `json:"response_cost"`
		ResolveCost  int64  `json:"resolve_cost"`
	}
	number := c.Query("no")
	if number == "" {
		c.JSON(http.StatusOK, status_400("tt单号不允许为空"))
		return
	}

	var resp ticket

	if err := orm.Db.Table("openc3_tt_ticket").Where("no = ?", number).Select("id, no, response_cost, resolve_cost, status").Find(&resp).Error; err != nil {
		c.JSON(http.StatusOK, status_400_v2(err.Error()))
	} else {
		c.JSON(http.StatusOK, status_200_v2(resp))
	}
}
