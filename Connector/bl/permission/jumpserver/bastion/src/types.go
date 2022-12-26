package src

type AuthenticateBody struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type AuthenticateResponse struct {
	Token string `json:"token"`
}

type UpsertAssetRequest struct {
	Id       string `json:"id"`
	HostName string `json:"hostname"`
	Ip       string `json:"ip"`
	Platform string `json:"platform"`
	Comment  string `json:"comment"`
}

type CreateUserRequest struct {
	Username           string   `json:"username"`
	Name               string   `json:"name"`
	Email              string   `json:"email"`
	MfaLevel           int      `json:"mfa_level"`
	NeedUpdatePassword bool     `json:"need_update_password"`
	Password           string   `json:"password"`
	PasswordStrategy   string   `json:"password_strategy"`
	Phone              string   `json:"phone"`
	Source             string   `json:"source"`
	SystemRoles        []string `json:"system_roles"`
}

type CreateSystemUserRequest struct {
	AutoGenerateKey      bool   `json:"auto_generate_key"`
	AutoPush             bool   `json:"auto_push"`
	Home                 string `json:"home"`
	LoginMode            string `json:"login_mode"`
	Name                 string `json:"name"`
	Password             string `json:"password"`
	Priority             int    `json:"priority"`
	Protocol             string `json:"protocol"`
	SftpRoot             string `json:"sftp_root"`
	Shell                string `json:"shell"`
	SuEnabled            bool   `json:"su_enabled"`
	Sudo                 string `json:"sudo"`
	Username             string `json:"username"`
	UsernameSameWithUser bool   `json:"username_same_with_user"`
}

type CreateAssetPermissionRequest struct {
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
