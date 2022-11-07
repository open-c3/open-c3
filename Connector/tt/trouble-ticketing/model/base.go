package model

type BaseImpact struct {
	ID          int64  `json:"id"`
	Name        string `json:"name"`
	Level       int64  `json:"level"`
	ResponseSLA int64  `json:"response_sla"`
	ResolveSLA  int64  `json:"resolve_sla"`
}
type BaseCategory struct {
	ID   int64  `json:"id"`
	Name string `json:"name"`
}
type BaseType struct {
	ID         int64  `json:"id"`
	Name       string `json:"name"`
	CategoryId int64  `json:"category_id"`
}
type BaseItem struct {
	ID         int64  `json:"id"`
	Name       string `json:"name"`
	TypeId     int64  `json:"type_id"`
	TplTitle   string `json:"tpl_title"`
	TplContent string `json:"tpl_content"`
}
type BaseGroup struct {
	ID            int64  `json:"id"`
	GroupName     string `json:"group_name"`
	GroupEmail    string `json:"group_email"`
	AdminEmail    string `json:"admin_email"`
	Timezone      int64  `json:"timezone"`
	WorkDay       string `json:"work_day"`
	WorkHourStart int64  `json:"work_hour_start"`
	WorkHourEnd   int64  `json:"work_hour_end"`
	Level1Report  string `json:"level1_report"`
	Level2Report  string `json:"level2_report"`
	Level3Report  string `json:"level3_report"`
	Level4Report  string `json:"level4_report"`
	Level5Report  string `json:"level5_report"`
	Disabled      int64  `json:"disabled"`
}
type BaseItemGroupMap struct {
	ID       int64 `json:"id"`
	GroupId  int64 `json:"group_id"`
	ItemId   int64 `json:"item_id"`
	Priority int64 `json:"priority"`
}
type BaseGroupUser struct {
	ID       int64  `json:"id"`
	GroupId  int64  `json:"group_id"`
	Email    string `json:"email"`
	Priority int64  `json:"priority"`
	Disabled int64  `json:"disabled"`
}
type BaseEmailTemplates struct {
	ID          int64  `json:"id"`
	Name        string `json:"name"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Content     string `json:"content"`
}
