package model

import (
	"bl/src/bastion/bastion"
)

type MachineInfo struct {
	UUID       string `json:"uuid"`
	InstanceId string `json:"instanceId"`
	HostName   string `json:"hostName"`
	IP         string `json:"ip"`
	// 取值 Linux Windows
	OS string `json:"os"`
	// 云前缀+vpc名称, 比如
	// QCloud_xxxxx
	// IBM_xxxxx
	// AWS_xxxxx
	// Huawei_xxxxx
	// Aliyun_xxxxx
	Site    string `json:"site"`
	VpcId   string `json:"vpc_id"`
	VpcName string `json:"vpc_name"`
}

type Bastion struct {
	Manufacturer      bastion.Manufacturer `json:"manufacturer" bson:"manufacturer"`
	AuthUser          string               `json:"authUser" bson:"authUser"`
	AuthPass          string               `json:"authPass" bson:"authPass"`
	BaseUrl           string               `json:"baseUrl"  bson:"baseUrl"`
	FilterVpcKeyWords []string             `json:"filterVpcKeyWords"  bson:"filterVpcKeyWords"`
}
