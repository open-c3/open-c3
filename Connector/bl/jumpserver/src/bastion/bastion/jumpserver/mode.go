package jumpserver

// Asset 堡垒机里管理的服务器资产条目
type Asset struct {
	Id       string `json:"id"`
	HostName string `json:"hostname"`
	Ip       string `json:"ip"`
	Comment  string `json:"comment"`
}

// User 堡垒机里的用户
type User struct {
	Id       string `json:"id"`
	Name     string `json:"name"`
	UserName string `json:"username"`
}

// SystemUser 系统用户
type SystemUser struct {
	Id       string `json:"id"`
	Name     string `json:"name"`
	UserName string `json:"username"`
}

// AssetPermission 资源授权
type AssetPermission struct {
	Id          string   `json:"id"`
	Name        string   `json:"name"`
	Actions     []string `json:"actions"`
	Assets      []string `json:"assets"`
	Users       []string `json:"users"`
	SystemUsers []string `json:"system_users"`
	DateExpired string   `json:"date_expired"`
	DateStart   string   `json:"date_start"`
	IsActive    bool     `json:"is_active"`
	IsExpired   bool     `json:"is_expired"`
	IsValid     bool     `json:"is_valid"`
	Nodes       []string `json:"nodes"`
	UserGroups  []string `json:"user_groups"`
}
