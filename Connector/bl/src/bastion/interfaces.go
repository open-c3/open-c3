package bastion

import (
	"bl/src/bastion/bastion"
	"bl/src/model"
)

type (
	CloudMachineInfoList interface {
		GetMachineInfoList() ([]model.MachineInfo, error)
	}

	SyncBastion interface {
		SetToken() error
		GetManufacturer() bastion.Manufacturer
		GetFilterVpcKeywords() []string
		GetBastionData() model.Bastion
		GetAssetMap(localMachines []model.MachineInfo) (map[interface{}]model.MachineInfo, map[interface{}]interface{}, error)
		CompareMachineInfoAndAsset(machineInfo model.MachineInfo, asset interface{}) (*bool, error)
		DeleteAsset(id interface{}) error
		CreateOrUpdateAsset(machineInfo model.MachineInfo) error
	}
)
