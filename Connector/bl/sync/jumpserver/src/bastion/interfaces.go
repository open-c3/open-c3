package bastion

import (
	"bl/src/bastion/bastion/jumpserver"
	"bl/src/model"
)

type (
	CloudMachineInfoList interface {
		GetMachineInfoList(appName, appKey string) ([]model.MachineInfo, error)
	}

	SyncBastion interface {
		SetToken() error
		GetAssetMap(localMachines []model.MachineInfo) (map[string]model.MachineInfo, map[string]jumpserver.Asset, error)
		CompareMachineInfoAndAsset(machineInfo model.MachineInfo, asset interface{}) (*bool, error)
		DeleteAsset(id interface{}) error
		CreateOrUpdateAsset(machineInfo model.MachineInfo) error
	}
)
