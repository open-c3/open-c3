package bastion

import (
	"bl/src/bastion/bastion/jumpserver"
	"bl/src/bastion/source"
	"bl/src/logger"
	"bl/src/model"
)

var (
	supportedDataSource = []CloudMachineInfoList{
		source.C3MachineInfoList{},
	}
)

func NewBastion(bl model.Bastion) SyncBastion {
	return jumpserver.NewBastion(bl)
}

func Helper(syncBastion SyncBastion, appName, appKey string) error {
	var (
		machinesList []model.MachineInfo
		err          error
	)

	for _, dataSource := range supportedDataSource {
		list, err := dataSource.GetMachineInfoList(appName, appKey)
		if err != nil {
			logger.FsErrorf("Helper.GetMachineInfoList.err: %v", err)
			return err
		}
		if len(list) > 0 {
			machinesList = append(machinesList, list...)
		}
	}

	mLocal, mBastion, err := syncBastion.GetAssetMap(machinesList)
	if err != nil {
		logger.FsErrorf("Helper.GetAssetMap.err: %v", err)
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
				logger.FsErrorf("Helper.CompareMachineInfoAndAsset.err: %v", err)
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
		if _, ok := mLocal[uuid]; !ok {
			needDeleteAssets = append(needDeleteAssets, asset)
		}
	}

	logger.FsInfof("Helper. len(needUpsertList) = %v, len(needDeleteAssets) =  %v\n", len(needUpsertList), len(needDeleteAssets))

	// 为了防止出现某些意外导致从堡垒机清空资产，如果要删除的数目远大于要更新的数目，那就不进行操作
	lenOfUpsert := len(needUpsertList)
	lenOfDelete := len(needDeleteAssets)
	if lenOfUpsert == 0 {
		lenOfUpsert = 1
	}
	if lenOfDelete/lenOfUpsert < 10 {
		for index, asset := range needDeleteAssets {
			logger.FsInfof("Helper.DeleteAsset. index = %v", index)
			err = syncBastion.DeleteAsset(asset)
			if err != nil {
				logger.FsErrorf("Helper.DeleteAsset.err: %v", err)
				return err
			}
		}
	}

	logger.FsInfof("Helper. 新增或更新机器总数 =  %v", len(needUpsertList))
	for _, machine := range needUpsertList {
		err = syncBastion.CreateOrUpdateAsset(machine)
		if err != nil {
			logger.FsErrorf("Helper.CreateAsset.err: %v", err)
			return err
		}
	}

	logger.FsInfof("Helper. jumpserver堡垒机同步结束")
	return nil
}
