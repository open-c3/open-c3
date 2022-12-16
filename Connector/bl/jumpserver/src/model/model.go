package model

type MachineInfo struct {
	InstanceId string `json:"instanceId"`
	HostName   string `json:"hostName"`
	IP         string `json:"ip"`
	// 取值 Linux Unix MacOS BSD Windows Other
	OS string `json:"os"`
}

type Bastion struct {
	User string
	Pass string
	Url  string
}
