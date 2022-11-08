package handler

import (
	"fmt"
	"net/http"
	"strings"

	"openc3.org/trouble-ticketing/funcs"
	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"

	"github.com/gin-gonic/gin"
)

// -- impact
func GetBaseImpact(c *gin.Context) {
	id := c.Param("id")
	obj := make([]model.BaseImpact, 0)
	if id != "/" {
		orm.Db.Table("openc3_tt_base_impact").Where("id = ?", strings.Split(id, "/")[1]).Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	} else {
		orm.Db.Table("openc3_tt_base_impact").Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	}
}

func PostBaseImpact(c *gin.Context) {
	var obj model.BaseImpact
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_impact").Create(&obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func PutBaseImpact(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseImpact
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_impact").Where("id = ?", id).Update(obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func DeleteBaseImpact(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseImpact
	db := orm.Db.Table("openc3_tt_base_impact").Where("id = ?", id).Delete(obj)
	if err := db.Error; err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}
	affected := db.RowsAffected
	c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
}

// -- category
func GetBaseCategory(c *gin.Context) {
	id := c.Param("id")
	obj := make([]model.BaseCategory, 0)
	if id != "/" {
		orm.Db.Table("openc3_tt_base_category").Where("id = ?", strings.Split(id, "/")[1]).Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	} else {
		orm.Db.Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	}
}

func PostBaseCategory(c *gin.Context) {
	var obj model.BaseCategory
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_category").Create(&obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func PutBaseCategory(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseCategory
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_category").Where("id = ?", id).Update(obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func DeleteBaseCategory(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseCategory
	db := orm.Db.Table("openc3_tt_base_category").Where("id = ?", id).Delete(obj)
	if err := db.Error; err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}
	affected := db.RowsAffected
	c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
}

// -- type
func GetBaseType(c *gin.Context) {
	id := c.Param("id")
	obj := make([]model.BaseType, 0)
	if id != "/" {
		orm.Db.Table("openc3_tt_base_type").Where("id = ?", strings.Split(id, "/")[1]).Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	} else {
		orm.Db.Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	}
}

func PostBaseType(c *gin.Context) {
	var obj model.BaseType
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_type").Create(&obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func PutBaseType(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseType
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_type").Where("id = ?", id).Update(obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func DeleteBaseType(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseType
	db := orm.Db.Table("openc3_tt_base_type").Where("id = ?", id).Delete(obj)
	if err := db.Error; err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}
	affected := db.RowsAffected
	c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
}

// -- item
func GetBaseItem(c *gin.Context) {
	id := c.Param("id")
	obj := make([]model.BaseItem, 0)
	if id != "/" {
		orm.Db.Table("openc3_tt_base_item").Where("id = ?", strings.Split(id, "/")[1]).Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	} else {
		orm.Db.Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	}
}

func PostBaseItem(c *gin.Context) {
	var obj model.BaseItem
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_item").Create(&obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func PutBaseItem(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseItem
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_item").Where("id = ?", id).Update(obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func DeleteBaseItem(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseItem
	db := orm.Db.Table("openc3_tt_base_item").Where("id = ?", id).Delete(obj)
	if err := db.Error; err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}
	affected := db.RowsAffected
	c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
}

// -- group
func GetBaseGroup(c *gin.Context) {
	type groupUser struct {
		model.BaseGroup
		Users []model.BaseGroupUser `json:"users"`
	}
	users := make([]model.BaseGroupUser, 0)
	orm.Db.Table("openc3_tt_base_group_user").Order("priority ASC").Find(&users)

	id := c.Param("id")
	obj := make([]groupUser, 0)
	if id != "/" {
		orm.Db.Table("openc3_tt_base_group").Where("id = ?", strings.Split(id, "/")[1]).Find(&obj)
	} else {
		orm.Db.Table("openc3_tt_base_group").Find(&obj)
	}

	for k, g := range obj {
		g.Users = make([]model.BaseGroupUser, 0)
		for _, user := range users {
			if user.GroupId == g.ID {
				obj[k].Users = append(obj[k].Users, user)
			}
		}
	}
	c.JSON(http.StatusOK, status_200(obj))
}

func PostBaseGroup(c *gin.Context) {
	var obj model.BaseGroup
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_group").Create(&obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func PutBaseGroup(c *gin.Context) {
	id := c.Param("id")
	var getObj model.BaseGroup
	var obj model.BaseGroup
	if c.BindJSON(&obj) == nil {

		oauser, _ := c.Get("oauser")
		orm.Db.Table("openc3_tt_base_group").Where("id = ?", id).First(&getObj)
		// 是组管理员 或 admin 才可以修改
		if getObj.AdminEmail == oauser.(string) || funcs.CheckPmsRole(c.Request, "tt_admin") {

			db := orm.Db.Table("openc3_tt_base_group").Where("id = ?", id).Update(obj)
			if err := db.Error; err != nil {
				c.JSON(http.StatusOK, status_400(err.Error()))
				return
			}

			affected := db.RowsAffected
			c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))

		} else {
			c.JSON(http.StatusOK, status_403("no priv."))
			return
		}

	}
}

func DeleteBaseGroup(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseGroup
	db := orm.Db.Table("openc3_tt_base_group").Where("id = ?", id).Delete(obj)
	if err := db.Error; err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}
	affected := db.RowsAffected
	c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
}

// -- item-group-map
func GetBaseItemGroupMap(c *gin.Context) {
	id := c.Param("id")
	obj := make([]model.BaseItemGroupMap, 0)
	if id != "/" {
		orm.Db.Table("openc3_tt_base_item_group_map").Where("id = ?", strings.Split(id, "/")[1]).Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	} else {
		orm.Db.Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	}
}

func PostBaseItemGroupMap(c *gin.Context) {
	var obj model.BaseItemGroupMap
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_item_group_map").Create(&obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func PutBaseItemGroupMap(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseItemGroupMap
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_item_group_map").Where("id = ?", id).Update(obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func DeleteBaseItemGroupMap(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseItemGroupMap
	db := orm.Db.Table("openc3_tt_base_item_group_map").Where("id = ?", id).Delete(obj)
	if err := db.Error; err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}
	affected := db.RowsAffected
	c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
}

// -- group-user
func GetBaseGroupUser(c *gin.Context) {
	id := c.Param("id")
	obj := make([]model.BaseGroupUser, 0)
	if id != "/" {
		orm.Db.Table("openc3_tt_base_group_user").Where("id = ?", strings.Split(id, "/")[1]).Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	} else {
		orm.Db.Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	}
}

func PostBaseGroupUser(c *gin.Context) {

	var group model.BaseGroup
	var obj model.BaseGroupUser

	if c.BindJSON(&obj) == nil {

		oauser, _ := c.Get("oauser")
		orm.Db.Table("openc3_tt_base_group").Where("id = ?", obj.GroupId).First(&group)

		// 是组管理员 或 admin 才可以添加 组员
		if group.AdminEmail == oauser.(string) || funcs.CheckPmsRole(c.Request, "tt_admin") {
			db := orm.Db.Table("openc3_tt_base_group_user").Create(&obj)
			if err := db.Error; err != nil {
				c.JSON(http.StatusOK, status_400(err.Error()))
				return
			}
			affected := db.RowsAffected
			c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
		} else {
			c.JSON(http.StatusOK, status_403("no priv."))
			return
		}

	}
}

func PutBaseGroupUser(c *gin.Context) {

	id := c.Param("id")
	var obj model.BaseGroupUser
	var group model.BaseGroup
	var getObj model.BaseGroupUser

	if c.BindJSON(&obj) == nil {

		orm.Db.Table("openc3_tt_base_group_user").Where("id = ?", id).First(&getObj)

		oauser, _ := c.Get("oauser")
		orm.Db.Table("openc3_tt_base_group").Where("id = ?", getObj.GroupId).First(&group)

		// 是组管理员 或 admin 才可以修改组员
		if group.AdminEmail == oauser.(string) || funcs.CheckPmsRole(c.Request, "tt_admin") {
			db := orm.Db.Table("openc3_tt_base_group_user").Where("id = ?", id).Save(obj)
			if err := db.Error; err != nil {
				c.JSON(http.StatusOK, status_400(err.Error()))
				return
			}
			affected := db.RowsAffected
			c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
		} else {
			c.JSON(http.StatusOK, status_403("no priv."))
			return
		}
	}
}

func DeleteBaseGroupUser(c *gin.Context) {

	id := c.Param("id")
	var group model.BaseGroup
	var obj model.BaseGroupUser
	var getObj model.BaseGroupUser

	orm.Db.Table("openc3_tt_base_group_user").Where("id = ?", id).First(&getObj)

	oauser, _ := c.Get("oauser")
	orm.Db.Table("openc3_tt_base_group").Where("id = ?", getObj.GroupId).First(&group)

	// 是组管理员 或 admin 才可以删除组员
	if group.AdminEmail == oauser.(string) || funcs.CheckPmsRole(c.Request, "tt_admin") {
		db := orm.Db.Table("openc3_tt_base_group_user").Where("id = ?", id).Delete(obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	} else {
		c.JSON(http.StatusOK, status_403("no priv."))
		return
	}

}

// -- email templates
func GetBaseEmailTemplates(c *gin.Context) {
	id := c.Param("id")
	obj := make([]model.BaseEmailTemplates, 0)
	if id != "/" {
		orm.Db.Table("openc3_tt_base_email_templates").Where("id = ?", strings.Split(id, "/")[1]).Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	} else {
		orm.Db.Find(&obj)
		c.JSON(http.StatusOK, status_200(obj))
	}
}

func PostBaseEmailTemplates(c *gin.Context) {
	var obj model.BaseEmailTemplates
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_email_templates").Create(&obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func PutBaseEmailTemplates(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseEmailTemplates
	if c.BindJSON(&obj) == nil {
		db := orm.Db.Table("openc3_tt_base_email_templates").Where("id = ?", id).Update(obj)
		if err := db.Error; err != nil {
			c.JSON(http.StatusOK, status_400(err.Error()))
			return
		}
		affected := db.RowsAffected
		c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
	}
}

func DeleteBaseEmailTemplates(c *gin.Context) {
	id := c.Param("id")
	var obj model.BaseEmailTemplates
	db := orm.Db.Table("openc3_tt_base_email_templates").Where("id = ?", id).Delete(obj)
	if err := db.Error; err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}
	affected := db.RowsAffected
	c.JSON(http.StatusOK, status_200(fmt.Sprintf("%d rows affected", affected)))
}

// -------------------------------------------------

// 获取所有base相关记录
func GetBaseAll(c *gin.Context) {

	type groupUser struct {
		model.BaseGroup
		Users []model.BaseGroupUser `json:"users"`
	}
	type resS struct {
		Impact       []model.BaseImpact       `json:"impact"`
		Category     []model.BaseCategory     `json:"category"`
		Type         []model.BaseType         `json:"type"`
		Item         []model.BaseItem         `json:"item"`
		Group        []groupUser              `json:"group"`
		ItemGroupMap []model.BaseItemGroupMap `json:"item_group_map"`
		GroupUser    []model.BaseGroupUser    `json:"group_user"`
	}

	var res resS
	res.Impact = make([]model.BaseImpact, 0)
	res.Category = make([]model.BaseCategory, 0)
	res.Type = make([]model.BaseType, 0)
	res.Item = make([]model.BaseItem, 0)
	res.Group = make([]groupUser, 0)
	res.ItemGroupMap = make([]model.BaseItemGroupMap, 0)
	res.GroupUser = make([]model.BaseGroupUser, 0)

	orm.Db.Table("openc3_tt_base_impact").Order("id ASC").Find(&res.Impact)
	orm.Db.Table("openc3_tt_base_category").Order("id ASC").Find(&res.Category)
	orm.Db.Table("openc3_tt_base_type").Order("id ASC").Find(&res.Type)
	orm.Db.Table("openc3_tt_base_item").Select("id, name, type_id").Order("id ASC").Find(&res.Item)
	orm.Db.Table("openc3_tt_base_group").Where("disabled = 0").Order("group_name ASC").Find(&res.Group)
	orm.Db.Table("openc3_tt_base_item_group_map").Order("priority ASC").Find(&res.ItemGroupMap)
	orm.Db.Table("openc3_tt_base_group_user").Order("priority ASC").Find(&res.GroupUser)

	for k, g := range res.Group {
		g.Users = make([]model.BaseGroupUser, 0)
		for _, user := range res.GroupUser {
			if user.GroupId == g.ID {
				res.Group[k].Users = append(res.Group[k].Users, user)
			}
		}
	}

	c.JSON(http.StatusOK, status_200(res))
}

// 获取CTI的树形map
/*
  c1 __ t1 __ i1
     |_ t2 __ i2
           |__ i3
*/
func GetCITtreeMap(c *gin.Context) {

	type typeS struct {
		model.BaseType
		Items []model.BaseItem `json:"items"`
	}

	type resS struct {
		model.BaseCategory
		Types []typeS `json:"types"`
	}

	category := make([]model.BaseCategory, 0)
	types := make([]model.BaseType, 0)
	items := make([]model.BaseItem, 0)
	orm.Db.Order("id").Find(&category)
	orm.Db.Order("id").Find(&types)
	orm.Db.Order("id").Find(&items)

	res := make([]resS, 0)
	for _, cat := range category {

		var res_tmp resS
		res_tmp.ID = cat.ID
		res_tmp.Name = cat.Name

		for _, t := range types {

			if t.CategoryId == cat.ID {

				var type_tmp typeS
				type_tmp.ID = t.ID
				type_tmp.Name = t.Name

				for _, i := range items {

					if i.TypeId == t.ID {
						type_tmp.Items = append(type_tmp.Items, i)
					}

				}

				res_tmp.Types = append(res_tmp.Types, type_tmp)
			}
		}

		res = append(res, res_tmp)
	}

	c.JSON(http.StatusOK, status_200(res))

}

// 获取group - user - item 关系
func GetGroupItemUserRel(c *gin.Context) {

	type resS struct {
		Group model.BaseGroup       `json:"group"`
		Items []string              `json:"items"`
		Users []model.BaseGroupUser `json:"users"`
	}
	res := make([]resS, 0)

	categorys := make([]model.BaseCategory, 0)
	types := make([]model.BaseType, 0)
	items := make([]model.BaseItem, 0)
	groups := make([]model.BaseGroup, 0)
	item_groups := make([]model.BaseItemGroupMap, 0)
	users := make([]model.BaseGroupUser, 0)

	orm.Db.Select("id,name,type_id").Order("id").Find(&items)
	orm.Db.Select("id,name,category_id").Order("id").Find(&types)
	orm.Db.Select("id,name").Order("id").Find(&categorys)
	orm.Db.Order("id").Find(&groups)
	orm.Db.Order("id").Find(&item_groups)
	orm.Db.Order("id").Find(&users)

	mapCategory := make(map[int64]model.BaseCategory)
	for _, c := range categorys {
		mapCategory[c.ID] = c
	}
	mapType := make(map[int64]model.BaseType)
	for _, t := range types {
		mapType[t.ID] = t
	}

	for _, group := range groups {
		var res_tmp resS
		res_tmp.Group = group
		for _, item_group := range item_groups {
			if item_group.GroupId == group.ID {
				for _, item := range items {
					if item.ID == item_group.ItemId {
						tmpStr := fmt.Sprintf("%s.%s.%s", mapCategory[mapType[item.TypeId].CategoryId].Name, mapType[item.TypeId].Name, item.Name)
						res_tmp.Items = append(res_tmp.Items, tmpStr)
					}
				}
			}
		}
		for _, user := range users {
			if user.GroupId == group.ID {
				res_tmp.Users = append(res_tmp.Users, user)
			}
		}
		res = append(res, res_tmp)
	}

	c.JSON(http.StatusOK, status_200(res))

}
