package bastion

import (
	"bl/src/bastion/bastion"
	"bl/src/bastion/bastion/jumpserver"
	"bl/src/bastion/source"
	"bl/src/logger"
	"bl/src/model"
	"fmt"
	"regexp"
	"strings"
)

var (
	BlManufacturerToCloudList = map[bastion.Manufacturer][]CloudMachineInfoList{
		bastion.ManufacturerJumpServer: {
			source.C3MachineInfoList{},
		},
	}
)

func NewBastion(bl model.Bastion) SyncBastion {
	switch bl.Manufacturer {
	case bastion.ManufacturerJumpServer:
		return jumpserver.NewBastion(bl)
	default:
		errMsg := fmt.Sprintf("不受支持的堡垒机类型: %v", bl.Manufacturer)
		logger.FsErrorf("NewBastion.err: %v", errMsg)
		return nil
	}
}

func BastionHelper(syncBastion SyncBastion) error {
	var (
		machinesList         []model.MachineInfo
		filteredMachinesList = make([]model.MachineInfo, 0)
		err                  error
	)

	dataSourceList, ok := BlManufacturerToCloudList[syncBastion.GetManufacturer()]
	if !ok {
		return nil
	}

	for _, dataSource := range dataSourceList {
		list, err := dataSource.GetMachineInfoList()
		if err != nil {
			logger.FsErrorf("BastionHelper.GetMachineInfoList.err: %v", err)
			return err
		}
		if len(list) > 0 {
			machinesList = append(machinesList, list...)
		}
	}
	logger.FsDebugf("BastionHelper.keyword: %v", syncBastion.GetFilterVpcKeywords())

	// mm主要用来对ip去重。
	mm := make(map[string]struct{})
	for _, machine := range machinesList {
		if _, ok = mm[machine.IP]; ok {
			continue
		}
		mm[machine.IP] = struct{}{}
		hit := false
		for _, keyword := range syncBastion.GetFilterVpcKeywords() {
			if strings.Contains(machine.VpcName, keyword) {
				logger.FsErrorf("BastionHelper.忽略ip: %v", machine.IP)
				hit = true
				break
			}
		}
		if hit {
			continue
		}
		filteredMachinesList = append(filteredMachinesList, machine)
	}

	for k := range filteredMachinesList {
		if filteredMachinesList[k].HostName == "" {
			filteredMachinesList[k].HostName = filteredMachinesList[k].IP
		}
		patternsIP := `(\d+)\.(\d+)\.(\d+)\.(\d+)`
		reg, err := regexp.Compile(patternsIP)
		if err != nil {
			continue
		}
		res := reg.FindString(filteredMachinesList[k].IP)
		if res == "" {
			continue
		}
		if res == filteredMachinesList[k].IP {
			continue
		}
		filteredMachinesList[k].IP = res
	}

	mLocal, mBastion, err := syncBastion.GetAssetMap(filteredMachinesList)
	if err != nil {
		logger.FsErrorf("BastionHelper.GetAssetMap.err: %v", err)
		return err
	}

	var (
		needUpsertList   = make([]model.MachineInfo, 0)
		needDeleteAssets = make([]interface{}, 0)
	)

	for uuid, machineInfo := range mLocal {
		if machineInfo.IP == "" || machineInfo.HostName == "" {
			continue
		}

		if asset, ok := mBastion[uuid]; ok {
			same, err := syncBastion.CompareMachineInfoAndAsset(machineInfo, asset)
			if err != nil {
				logger.FsErrorf("BastionHelper.CompareMachineInfoAndAsset.err: %v", err)
				return err
			}
			if !*same {
				needUpsertList = append(needUpsertList, machineInfo)
			}
		} else {
			needUpsertList = append(needUpsertList, machineInfo)
		}
	}

	for uuid, asset := range mBastion {
		if _, ok = mLocal[uuid]; !ok {
			needDeleteAssets = append(needDeleteAssets, asset)
		}
	}

	logger.FsInfof("BastionHelper. len(needUpsertList) = %v, len(needDeleteAssets) =  %v\n", len(needUpsertList), len(needDeleteAssets))

	// 为了防止出现某些意外导致从堡垒机清空资产，如果要删除的数目远大于要更新的数目，那就不进行操作
	lenOfUpsert := len(needUpsertList)
	lenOfDelete := len(needDeleteAssets)
	if lenOfUpsert == 0 {
		lenOfUpsert = 1
	}
	if lenOfDelete/lenOfUpsert < 10 {
		for index, asset := range needDeleteAssets {
			logger.FsInfof("BastionHelper.DeleteAsset. index = %v", index)
			err = syncBastion.DeleteAsset(asset)
			if err != nil {
				logger.FsErrorf("BastionHelper.DeleteAsset.err: %v", err)
				return err
			}
		}
	}

	logger.FsInfof("BastionHelper. 新增或更新机器总数 =  %v", len(needUpsertList))
	for _, machine := range needUpsertList {
		err = syncBastion.CreateOrUpdateAsset(machine)
		if err != nil {
			logger.FsErrorf("BastionHelper.CreateAsset.err: %v", err)
			return err
		}
	}

	logger.FsInfof(fmt.Sprintf("BastionHelper. 堡垒机: %v 同步结束", syncBastion.GetManufacturer()))
	return nil
}
