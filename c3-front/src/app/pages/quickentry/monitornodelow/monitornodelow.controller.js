(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonitorNodeLowController', MonitorNodeLowController);

    function MonitorNodeLowController($state, $http, $uibModal, treeService, ngTableParams, $scope, $injector, $timeout) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.lowUtilizationList = [   // 低利用率Tab列表
          {
            id: 'compute',
            name: '主机'
          },
        ]
        vm.tabThead = ['lowstatus', '服务树'];
        vm.checkOwnerStatus = true
        $scope.countOptions = [20, 30,50, 100, 500]
        $scope.selectTab = vm.lowUtilizationList[0];
        vm.headerList = []
        vm.downloadTitle  = []
        vm.activedStatus = ''
        vm.monitorDataCardList = [
          {
            name: 'C3T.资源数量',
            status: '',
            count: 0,
            color: '#339094',
            description: ''
          },
          {
            name: 'C3T.利用率低',
            status: 'low',
            count: 0,
            color: 'red',
            description: ''
          },
          {
            name: 'C3T.警告',
            status: 'warn',
            count: 0,
            color: '#f6bb42',
            description: ''
          },
          {
            name: 'C3T.正常',
            status: 'normal',
            count: 0,
            color: 'green',
            description: ''
          },
          {
            name: 'C3T.未知',
            status: 'unknown',
            count: 0,
            color: '#000',
            description: ''
          },
        ]
        vm.statusColorMap = {
          low: 'red',
          warn: '#f6bb42',
          normal: 'green',
          unknown: '#000',
        }

        vm.checkboxes = {
          checked: false,
          items: {},
        };
        vm.checkDataList = []
        vm.checkOtherDataList = []

        vm.userInfo = sessionStorage.getItem('userInfo')? JSON.parse(sessionStorage.getItem('userInfo')): {}
        vm.markSelected = 'all'
        vm.tableInstanceId = ''
        vm.tableBusinessOwner = ''
        vm.markStatusOption = [{value: 'all', label: '全部'}]
        vm.dialogStatusList = []
        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.downloadData = [];
        vm.computeDownloadTitleMap = {
          id: '编号',
          name: '主机名',
          hostname: '名称',
          owner: 'Owner',
          instancetype: '实例类型',
          inip: '内网IP',
          exip: '外网IP',
          type: '资源类型',
          status: '状态',
          lowcnt: '低利用率天数/14天',
          cpu: 'CPU(%)',
          mem:'内存(%)',
          netin: '下载带宽',
          netout: '上传带宽',
          date: '最后统计日期',
        };
        vm.filterData = []
        vm.reverseName = ''
        vm.reverseHosttName = ''
        vm.reverseOwner = ''
        vm.isShowFilter = false

        vm.openNewWindow = function( ip )
        {
            var url = '/third-party/monitor/grafana/d/rYdddlPWk/node-exporter-full?orgId=1&from=now-14d&to=now&var-DS_PROMETHEUS=default&var-job=openc3&var-node=' + ip + '&var-diskdevices=%5Ba-z%5D%2B%7Cnvme%5B0-9%5D%2Bn%5B0-9%5D%2B%7Cmmcblk%5B0-9%5D%2B';
            window.open( url, '_blank')
        }

        vm.allData = [];

        vm.stat = '';
        vm.dataGrep = function( stat ){
            vm.activedStatus = stat
            vm.stat = stat;
            vm.tempdata = [];
            angular.forEach(vm.allData, function (data, index) {
              if(stat === '') {
                vm.tempdata = vm.allData
              }
              if ($scope.selectTab.id === 'compute') {
                if( data.status == stat)
                {
                    vm.tempdata.push( data );
                }
                vm.filterData = vm.tempdata
              } else {
                if( data.lowstatus == stat)
                {
                    vm.tempdata.push( data );
                }
              }
           });
           vm.downloadData = vm.tempdata.slice().reverse()
           vm.dataTable = new ngTableParams({count:20}, {counts:$scope.countOptions,data:vm.tempdata.reverse()});
        }

        // 获取主机低利用率Tab列表
        vm.getTabsData = function () {
          $http.get(`/api/agent/resourcelow/type`).success(function (data) {
            if (data.stat == true) {
              vm.lowUtilizationList.push(...data.data.map(item => {
                return { id: item, name: item }
              }))
            }
            else {
              toastr.error("加载数据失败:" + data.info)
            }
          })
        };

        vm.getTabsData();

        // 获取某个类型的标记数据
        vm.getMarkData = function () {
          vm.loadover = false;
          vm.headerList = []
          vm.dataTable = new ngTableParams({count:20}, {counts:$scope.countOptions,data:[]});
          const type = $scope.selectTab.id
          $http.get(`/api/agent/resourcelow/mark/${type}/${vm.treeid}`).success(function (data) {
            if (data.stat == true) {
              vm.selectRemark = data.data
              vm.reload()
            } else {
              toastr.error("加载数据失败:" + data.info)
            }
          });
        }

        // 获取状态列表
        vm.getStatusList = function () {
          $http.get('/api/agent/resourcelow/status').success(function (data) {
            if (data.stat == true) {
              vm.dialogStatusList = data.data
              vm.markStatusOption.push(...data.data.map(item => {
                return {value: item.name, label: item.name}
              }))
            } else {
              toastr.error("加载数据失败:" + data.info)
            }
          });
        }

        vm.getStatusList();

        vm.handleOwnerStatus = function () {
          vm.getMarkData()
        }

        // 防抖函数
       let timeout = null
       vm.debounce = function (fn, delay) {
        if (timeout) {
          $timeout.cancel(timeout)
        }
        timeout = $timeout(function () { fn() }, delay)
       }

        // 反选change事件
        vm.handleReverseChange = function () {
          vm.debounce(function () {
            const selectData = JSON.parse(JSON.stringify(vm.filterData))
            const tableFilterObj = JSON.parse(JSON.stringify(vm.dataTable.filter()))
            const reverseFilter = function (item) {
              return (vm.reverseName === ''? item.name: !item.name.includes(vm.reverseName)) && 
              (vm.reverseHosttName === ''? item.hostname: !item.hostname.includes(vm.reverseHosttName)) && 
              (vm.reverseOwner === ''? item.owner:!item.owner.includes(vm.reverseOwner))
            }
            if ($scope.selectTab.id === 'compute') {
              if (Object.values(tableFilterObj).join('').length === 0) {
                const checkFilterData = selectData.filter(item => reverseFilter(item))
                vm.dataTable = new ngTableParams({count:20}, {counts:$scope.countOptions,data:checkFilterData});
              } else {
                const hasFilterData = selectData.filter(item => {
                  for (let key in item) {
                    if (item.hasOwnProperty(key) && String(item[key]).includes(tableFilterObj[key])) {
                      return true;
                    }
                  }
                  return false;
                })
                const checkFilterData = hasFilterData.filter(item => reverseFilter(item))
                  // 重新设置表格的数据
                  var tableSettings = vm.dataTable.settings();
                  if (tableSettings) {
                    tableSettings.data = checkFilterData
                  }
                  vm.dataTable.reload();
              }
            }
          }, 800)
        }

        vm.handleIsShowFilter = function () {
          vm.isShowFilter = !vm.isShowFilter
          vm.reverseName = ''
          vm.reverseHosttName = ''
          vm.reverseOwner = ''
        }

        vm.reload = function () {
          let remarkMap = []
          const newArr = []
          angular.forEach(vm.selectRemark, function (value, key) {
            remarkMap.push({key, status:value.status, mark: value.mark})
          })
          vm.loadover = false;
          if ($scope.selectTab.id === 'compute') {
            $http.get(`/api/agent/nodelow/${vm.treeid}${vm.checkOwnerStatus === true? `?owner=${vm.userInfo.email}`: ''}`).success(function (data) {
              vm.loadover = true;
              if (data.stat == true) {
                angular.forEach(data.data, function (value) {
                  if (remarkMap.filter(item => item.key === value.ip).length > 0) {
                    value.remark = remarkMap.filter(item => item.key === value.ip)[0].mark
                    value.remarkStatus = remarkMap.filter(item => item.key === value.ip)[0].status
                  }else {
                    value.mark = '-'
                    value.remarkStatus = '-'
                  }
                  newArr.push(value)
                })
                vm.downloadData = data.data.slice().reverse()
                vm.dataTable = new ngTableParams({ count: 20 }, { counts: $scope.countOptions, data: newArr.reverse() });
                vm.selectData = newArr
                vm.allData = data.data;
                vm.checkDataList = newArr
                vm.monitorDataCardList.map(item => item.count = newArr.filter(cItem => cItem.status === item.status).length)
                vm.monitorDataCardList.map(item => item.description = data.PolicyDescription[item.status])
                vm.monitorDataCardList[0].count = data.data.length
                vm.monitorDataCardList[0].description = ''
                vm.handleBusinessChange()
              } else {
                toastr.error("加载数据失败:" + data.info)
              }
            });
          } else {
            $http.get(`/api/agent/resourcelow/data/${$scope.selectTab.id}/${vm.treeid}${vm.checkOwnerStatus === true? `?owner=${vm.userInfo.email}`: ''}`).success(function (data) {
              vm.loadover = true;
              if (data.stat == true) {
                const newData = []
                let elementsToAdd = ['处理状态', '处理备注'];
                angular.forEach(data.data, function (value) {
                  value.ip = value['实例ID']
                  if (remarkMap.filter(item => item.key === value['实例ID']).length > 0) {
                    value['处理备注'] = remarkMap.filter(item => item.key === value['实例ID'])[0].mark
                    value['处理状态'] = remarkMap.filter(item => item.key === value['实例ID'])[0].status
                  }else {
                    value['处理备注']  = '-'
                    value['处理状态'] = '-'
                  }
                  newData.push(value)
                })
                vm.headerList = data.title
                vm.downloadTitle = data.title
                vm.headerList.splice(1, 0, ...elementsToAdd)
                vm.downloadData = data.data.slice().reverse()
                vm.dataTable = new ngTableParams({ count: 20 }, { counts: $scope.countOptions, data: newData.reverse() });
                vm.selectData = newData
                vm.allData = data.data;
                vm.checkDataList = newData
                vm.monitorDataCardList.map(item => item.count = data.data.filter(cItem => cItem.lowstatus === item.status).length)
                vm.monitorDataCardList.map(item => item.description = data.PolicyDescription[item.status])
                vm.monitorDataCardList[0].count = data.data.length
                vm.monitorDataCardList[0].description = ''
                vm.handleBusinessChange()
              } else {
                toastr.error("加载数据失败:" + data.info)
              }
            });
          }
        };

        

        vm.keepDecimal = function (number) {
          if (!number || number === '') {
            return number;
          };
          const num = Number(number);
          const mbUnit = 1024 * 1024;
          const kbUnit = 1024;
          if (num >= mbUnit) {
            return `${(num/mbUnit).toFixed(2)}Mb/s`;
          } else if (num >= kbUnit && num < mbUnit) {
            return `${(num/kbUnit).toFixed(2)}Kb/s`;
          } else if (num >= 0 && num < kbUnit) {
            return `${num}b/s`;
          }

        }

        vm.downloadFunc = function (fileName) {
          const downLoadArr = [];
          if ($scope.selectTab && $scope.selectTab.id === 'compute') {         
            vm.downloadData.map(item => {
              item.netin = vm.keepDecimal(item.netin)||'';
              item.netout =  vm.keepDecimal(item.netout) || '';
              const newData = {};
              angular.forEach(vm.computeDownloadTitleMap, function (key,value) { 
                newData[key] = item[value]
              })  
              downLoadArr.push(newData)
            });
          } else {
            if (!vm.downloadTitle) {
              vm.downloadTitle = []
            }
            vm.downloadData.forEach(item => {
              const newData = {}
              vm.downloadTitle.forEach(cItem => {
                newData[cItem] = item[cItem]
              })
              downLoadArr.push(newData)
            })
          }
          const workbook = XLSX.utils.book_new();
          const worksheet = XLSX.utils.json_to_sheet(downLoadArr);
          XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');
          const wbout = XLSX.write(workbook, { bookType: 'xlsx', type: 'array', stream: true });
          const blob = new Blob([wbout], { type: 'application/octet-stream' });
          saveAs(blob, fileName);
        }

        vm.showDetail = function (ip) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitornodelow/detail.html',
                controller: 'MonitorNodeLowDetailController',
                controllerAs: 'MonitorNodeLowDetail',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid },
                    reload: function () { return vm.getMarkData },
                    ip:     function () { return ip }
                }
            });
        };

        vm.handleMark = function (nodelowItems) {
          swal({
            title: '是否进行标记',
            type: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#DD6B55',
            cancelButtonText: '取消',
            confirmButtonText: '确定',
            closeOnConfirm: true
          }, function () {
            $http.post( `api/agent/nodelow/mark/${vm.treeid}/${nodelowItems.ip}`).success(function (data) {
              if (data.stat) {
                swal('操作成功!' , 'success');
                // vm.markHashReload();
              } else {
                swal({ title: '操作失败', text: data.info, type: 'error' });
              }
            });
          });
        }

        vm.handleChange = function () {
         vm.debounce(function () {
          const selectData = JSON.parse(JSON.stringify(vm.selectData))
          if ($scope.selectTab.id === 'compute') {
            const statusSelectData = selectData.filter(item => vm.markSelected === 'all'? item : item.remarkStatus === vm.markSelected)
            vm.filterData = statusSelectData
            vm.downloadData = statusSelectData.slice().reverse()
            vm.dataTable = new ngTableParams({count:20}, {counts:$scope.countOptions,data:statusSelectData});
          } else {
            const otherStatusSelectData = selectData.filter(item => {
              return (vm.markSelected === 'all'? item : item['处理状态'] === vm.markSelected) && 
              (item['实例ID'].includes(vm.tableInstanceId)) && 
              (item['业务负责人'].includes(vm.tableBusinessOwner))
            })
            vm.downloadData = otherStatusSelectData.slice().reverse()
            vm.dataTable = new ngTableParams({count:20}, {counts:$scope.countOptions,data:otherStatusSelectData.reverse()});
          }
         },800)
        }

        vm.handleInstanceChange = function () {
         vm.debounce(function () {
          const selectData = JSON.parse(JSON.stringify(vm.selectData))
          const instanceIdtData = selectData.filter(item => {
            return (vm.markSelected === 'all'? item : item['处理状态'] === vm.markSelected) && 
            (item['实例ID'].includes(vm.tableInstanceId)) && 
            (item['业务负责人'].includes(vm.tableBusinessOwner))
          })
          vm.downloadData = instanceIdtData.slice().reverse()
          vm.dataTable = new ngTableParams({count:20}, {counts:$scope.countOptions,data:instanceIdtData});
         },800)
        }

        vm.handleBusinessChange = function () {
         vm.debounce(function () {
          const selectData = JSON.parse(JSON.stringify(vm.selectData))
          if ($scope.selectTab.id === 'compute') {
            const businesstData = selectData.filter(item => {
              return (vm.markSelected === 'all' ? item : (item['remarkStatus']|| '') === vm.markSelected) &&
              ((item['owner']|| '').includes(vm.tableBusinessOwner))
            })
            vm.filterData = businesstData
            vm.downloadData = businesstData.slice().reverse()
            vm.dataTable = new ngTableParams({ count: 20 }, { counts: $scope.countOptions, data: businesstData });
          } else {
            const businesstData = selectData.filter(item => {
              return (vm.markSelected === 'all' ? item : item['处理状态'] === vm.markSelected) &&
                (item['实例ID'].includes(vm.tableInstanceId)) &&
                (item['业务负责人'].includes(vm.tableBusinessOwner))
            })
            vm.downloadData = businesstData.slice().reverse()
            vm.dataTable = new ngTableParams({ count: 20 }, { counts: $scope.countOptions, data: businesstData });
          }
         }, 800)
        }
        

        vm.handleTabChange =function (value) {
          vm.activedStatus = ''
          vm.tableBusinessOwner = ''
          $scope.selectTab = value
          vm.reverseName = ''
          vm.reverseHosttName = ''
          vm.reverseOwner = ''
        }

        // 更新视图
        vm.tableReload = function  () {
          vm.getMarkData()
          vm.checkboxes = {
            checked: false,
            items: {},
          };
        }
    // 编辑状态
    vm.handleEditStatus = function () {
      if (!vm.checkboxes.itemsNumber || vm.checkboxes.itemsNumber === 0) {
        toastr.error("请先勾选实例！")
        return false
      }
      const selectResourceArr = []
      angular.forEach(vm.checkboxes.items, function (value, key) {
        if (value) {
          selectResourceArr.push(key)
        }
      });
      const selectResDetail = vm.checkDataList.filter(item => selectResourceArr.find(cItem => cItem == item.ip));
      $uibModal.open({
        templateUrl: 'app/pages/quickentry/monitornodelow/dialog/editStatus.html',
        controller: 'EditStatusController',
        controllerAs: 'editStatus',
        backdrop: 'static',
        size: 'md',
        keyboard: false,
        bindToController: true,
        resolve: {
          type: function () { return $scope.selectTab.id },
          treeid: function () { return vm.treeid },
          selectResDetail: function () { return selectResDetail},
          tableReload: function () { return vm.tableReload },
          dialogStatusList: function () { return vm.dialogStatusList },
        }
      });
    }

    $scope.$watch('selectTab', function () {
      if ($scope.selectTab && $scope.selectTab.id) {
        vm.markSelected = 'all'
        vm.checkboxes = {
          checked: false,
          items: {},
        };
        vm.monitorDataCardList = [
          {
            name: 'C3T.资源数量',
            status: '',
            count: 0,
            color: '#339094',
            description: ''
          },
          {
            name: 'C3T.利用率低',
            status: 'low',
            count: 0,
            color: 'red',
            description: ''
          },
          {
            name: 'C3T.警告',
            status: 'warn',
            count: 0,
            color: '#f6bb42',
            description: ''
          },
          {
            name: 'C3T.正常',
            status: 'normal',
            count: 0,
            color: 'green',
            description: ''
          },
          {
            name: 'C3T.未知',
            status: 'unknown',
            count: 0,
            color: '#000',
            description: ''
          },
        ]
        vm.tableInstanceId = ''
        vm.tableBusinessOwner = ''
        vm.getMarkData();
      }
    })

    // 监听全选checkbox
    $scope.$watch(function () { return vm.checkboxes.checked }, function (value) {
      angular.forEach(vm.checkDataList, function (item, index, array) {
        vm.checkboxes.items[[array[index].id]] = value
      });
      vm.checkboxes.itemsNumber = Object.values(vm.checkboxes.items).filter(item => item === true).length
      let nodeList = []
      for (let key in vm.checkboxes.items) {
        nodeList.push(String(key))
      }
    }, true);

    // 监听单个列表项的checkbox
    $scope.$watch(function () { return vm.checkboxes.items }, function (value) {
      var checked = 0, unchecked = 0
      angular.forEach(vm.checkDataList, function (item, index, array) {
        checked += (vm.checkboxes.items[array[index].ip]) || 0;
        unchecked += (!vm.checkboxes.items[array[index].ip]) || 0;
      });
      if (vm.checkDataList.length > 0 && ((unchecked == 0) || (checked == 0))) {
        vm.checkboxes.checked = (checked == vm.checkDataList.length);
      }
      vm.checkboxes.itemsNumber = checked
      angular.element(document.getElementsByClassName("select-all")).prop("indeterminate", (checked != 0 && unchecked != 0));
    }, true);
    }
})();
