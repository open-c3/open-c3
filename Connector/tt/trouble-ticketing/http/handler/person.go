package handler

import (
	"errors"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/jinzhu/gorm"
	"net/http"
	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"
)

// 该文件主要用来处理为运维人员配置预配置的事件影响、C.T.I等等信息
// 以及根据指定的运维人员获取预配置的对应参数。

type CreatePersonParamsArgs struct {
	// 目标用户。可以为空。如果为空，在前端为"默认系统配置"
	TargetUser string `json:"target_user"`
	// 影响级别
	Impact int64 `json:"impact" binding:"required"`
	// 总类
	Category int64 `json:"category" binding:"required"`
	// 子类
	Type int64 `json:"type" binding:"required"`
	// 名目
	Item int64 `json:"item" binding:"required"`
	// 工作组
	WorkGroup int64 `json:"work_group" binding:"required"`
	// 组员
	GroupUser int64 `json:"group_user" binding:"required"`
}

// CreatePersonParams 创建运维人员预配置
//
// @Summary 创建运维人员预配置
// @Description 创建运维人员预配置
// @Tags 运维预配置
// @Accept json
// @Param body body CreatePersonParamsArgs true "请求体"
// @Success 200
// @Router /person/create [post]
func CreatePersonParams(c *gin.Context) {
	var params CreatePersonParamsArgs
	err := c.BindJSON(&params)
	if err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}

	if !CheckCTIRelation(params.Category, params.Type, params.Item) {
		c.JSON(http.StatusOK, status_400("cti参数配置错误"))
		return
	}

	var data model.PersonPreConfigParams
	data.TargetUser = params.TargetUser
	data.Impact = params.Impact
	data.Category = params.Category
	data.Type = params.Type
	data.Item = params.Item
	data.WorkGroup = params.WorkGroup
	data.GroupUser = params.GroupUser

	oaUser, _ := c.Get("oauser")
	data.EditUser = oaUser.(string)

	d := orm.Db.Create(&data)
	if err := d.Error; err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}

	if d.RowsAffected != 1 {
		c.JSON(http.StatusOK, status_400("出现错误"))
		return
	}
	c.JSON(http.StatusOK, status_200(data.ID))
}

// GetAllPersonParams 获取所有预配置的运维人员列表
//
// @Summary 获取所有运维人员预配置
// @Description 获取所有运维人员预配置
// @Tags 运维预配置
// @Accept json
// @Router /person/list [get]
func GetAllPersonParams(c *gin.Context) {
	var persons []model.PersonPreConfigParams

	// Fetch all records from the database
	d := orm.Db.Find(&persons)
	if d.Error != nil {
		c.JSON(http.StatusOK, status_400(d.Error.Error()))
		return
	}

	c.JSON(http.StatusOK, status_200(persons))
}

type CreatePersonParamsByCopyArgs struct {
	TemplateUser string `json:"template_user" binding:"required"`
	TargetUser   string `json:"target_user" binding:"required"`
}

// CreatePersonParamsByCopy 通过复制账号创建运维人员预配置
//
// @Summary 通过复制账号创建运维人员预配置
// @Description 通过复制账号创建运维人员预配置
// @Tags 运维预配置
// @Accept json
// @Param body body CreatePersonParamsByCopyArgs true "请求体"
// @Success 200
// @Router /person/create/by_copy [post]
func CreatePersonParamsByCopy(c *gin.Context) {
	var args CreatePersonParamsByCopyArgs

	err := c.BindJSON(&args)
	if err != nil {
		c.JSON(http.StatusOK, status_400(err))
		return
	}

	var personTemplate model.PersonPreConfigParams
	d := orm.Db.Where("target_user = ?", args.TemplateUser).First(&personTemplate)
	if d.Error != nil {
		if errors.Is(d.Error, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusOK, status_400("No record found for given template account"))
		} else {
			c.JSON(http.StatusOK, status_400(d.Error.Error()))
		}
		return
	}

	personTemplate.TargetUser = args.TargetUser

	oaUser, _ := c.Get("oauser")
	personTemplate.EditUser = oaUser.(string)

	personTemplate.ID = 0
	d = orm.Db.Create(&personTemplate)
	if err := d.Error; err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}

	if d.RowsAffected != 1 {
		c.JSON(http.StatusOK, status_400("出现错误"))
		return
	}
	c.JSON(http.StatusOK, status_200(personTemplate.ID))
}

// DeletePersonByTargetUser 根据TargetUser的id删除指定的账号
//
// @Summary 根据TargetUser的id删除指定的账号
// @Description 根据TargetUser的id删除指定的账号
// @Tags 运维预配置
// @Success 200
// @Router /person/delete/:id [delete]
func DeletePersonByTargetUser(c *gin.Context) {
	id := c.Param("id")

	d := orm.Db.Where("id = ?", id).Delete(&model.PersonPreConfigParams{})
	if d.Error != nil {
		c.JSON(http.StatusOK, status_400(d.Error.Error()))
		return
	}

	if d.RowsAffected < 1 {
		c.JSON(http.StatusOK, status_400(fmt.Sprintf("无法根据 id: %v 找到指定用户", id)))
		return
	}

	c.JSON(http.StatusOK, status_200("操作成功"))
}

// UpdatePersonByTargetUser 更新运维预配置
//
// @Summary 更新运维预配置
// @Description 更新运维预配置
// @Tags 运维预配置
// @Accept json
// @Param body body model.PersonPreConfigParams true "请求体"
// @Success 200
// @Router /person/update [post]
func UpdatePersonByTargetUser(c *gin.Context) {
	var updatedPerson model.PersonPreConfigParams

	err := c.BindJSON(&updatedPerson)
	if err != nil {
		c.JSON(http.StatusBadRequest, status_400(err))
		return
	}

	var existingPerson model.PersonPreConfigParams
	d := orm.Db.Where("id = ?", updatedPerson.ID).First(&existingPerson)
	if d.Error != nil {
		if errors.Is(d.Error, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusOK, status_400(fmt.Sprintf("无法根据 target_user: %v 找到指定用户", updatedPerson.TargetUser)))
			return
		}
		c.JSON(http.StatusOK, status_400(d.Error.Error()))
		return
	}

	oaUser, _ := c.Get("oauser")
	updatedPerson.EditUser = oaUser.(string)

	d = orm.Db.Model(&existingPerson).Updates(updatedPerson)
	if d.Error != nil {
		c.JSON(http.StatusOK, status_400(d.Error.Error()))
		return
	}

	c.JSON(http.StatusOK, status_200("操作成功"))
}
