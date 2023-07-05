(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonitorNodeLowController', MonitorNodeLowController);

    function MonitorNodeLowController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, genericService, $scope, $injector, $sce ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.lowUtilizationList = [   // 低利用率Tab列表
          {
            id: 'compute',
            name: '主机'
          },
        ]
        $scope.selectTab = vm.lowUtilizationList[0];
        vm.headerList = []
        vm.downloadTitle  = []
        vm.monitorDataCardList = [
          {
            name: 'C3T.利用率低',
            status: 'low',
            count: 0,
            color: 'red'
          },
          {
            name: 'C3T.警告',
            status: 'warn',
            count: 0,
            color: '#f6bb42'
          },
          {
            name: 'C3T.正常',
            status: 'normal',
            count: 0,
            color: 'green'
          },
          {
            name: 'C3T.未知',
            status: 'unkown',
            count: 0,
            color: '#000'
          },
        ]

        vm.checkboxes = {
          checked: false,
          items: {},
        };
        vm.checkDataList = []
        vm.checkOtherDataList = []

        vm.userInfo = {}
        vm.markSelected = 'all'
        vm.markSelectOption = [
          {value: 'all', label: '全部'},
          {value: 'computed', label: '已标记'},
          {value: 'undone', label: '未标记'},
        ]
        vm.hashMarkData = []
        vm.tableData = [];
        vm.exportDownload = genericService.exportDownload
        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.openNewWindow = function( ip )
        {
            var url = '/third-party/monitor/grafana/d/rYdddlPWk/node-exporter-full?orgId=1&from=now-14d&to=now&var-DS_PROMETHEUS=default&var-job=openc3&var-node=' + ip + '&var-diskdevices=%5Ba-z%5D%2B%7Cnvme%5B0-9%5D%2Bn%5B0-9%5D%2B%7Cmmcblk%5B0-9%5D%2B';
            window.open( url, '_blank')
        }

        vm.allData = [];

        vm.stat = '';
        vm.dataGrep = function( stat ){
            vm.stat = stat;
            vm.tempdata = [];
            angular.forEach(vm.allData, function (data, index) {
               if( data.status == stat )
               {
                   vm.tempdata.push( data );
               }
           });

           vm.dealWithData(vm.tempdata.slice().reverse(), $scope.selectTab.id)
           vm.dataTable = new ngTableParams({count:20}, {counts:[],data:vm.tempdata.reverse()});
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

        vm.reload = function () {
          let remarkMap = []
          const newArr = []
          angular.forEach(vm.selectRemark, function (value, key) {
            remarkMap.push({key, status:value.status, mark: value.mark})
          })
          if ($scope.selectTab.id === 'compute') {
            $http.get(`/api/agent/nodelow/${vm.treeid}`).success(function (data) {
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
                vm.dealWithData(data.data.slice().reverse(), $scope.selectTab.id)
                vm.dataTable = new ngTableParams({ count: 20 }, { counts: [], data: newArr.reverse() });
                vm.selectData = newArr
                vm.allData = data.data;
                vm.checkDataList = newArr
                vm.monitorDataCardList.map(item => item.count = newArr.filter(cItem => cItem.status === item.status).length)
                vm.loadover = true;
              } else {
                toastr.error("加载数据失败:" + data.info)
              }
            });
          } else {
            $http.get(`/api/agent/resourcelow/data/${$scope.selectTab.id}/${vm.treeid}`).success(function (data) {
              if (data.stat == true) {
                const newData = []
                let elementsToAdd = ['状态', '备注'];
                angular.forEach(data.data, function (value) {
                  value.name = value['名称']
                  if (remarkMap.filter(item => item.key === value['实例ID']).length > 0) {
                    value['备注'] = remarkMap.filter(item => item.key === value['实例ID'])[0].mark
                    value['状态'] = remarkMap.filter(item => item.key === value['实例ID'])[0].status
                  }else {
                    value['备注']  = '-'
                    value['状态'] = '-'
                  }
                  newData.push(value)
                })
                vm.headerList = data.title
                vm.downloadTitle = data.title
                vm.headerList.splice(1, 0, ...elementsToAdd)
                vm.dealWithData(data.data.slice().reverse(), $scope.selectTab.id)
                vm.dataTable = new ngTableParams({ count: 20 }, { counts: [], data: newData.reverse() });
                vm.selectData = newData
                vm.allData = data.data;
                vm.checkDataList = newData
                vm.monitorDataCardList.map(item => item.count = data.data.filter(cItem => cItem.lowstatus === item.status).length)
                vm.loadover = true;
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

        vm.dealWithData = function (data, type) {
          vm.tableData = []
          if (type === 'compute') {
            vm.exportDownloadStr = `<tr><td>编号</td><td>主机名</td><td>名称</td><td>Owner</td><td>资源类型</td><td>内网IP</td><td>外网IP</td><td>资源类型</td><td>状态</td><td>低利用率天数/14天</td><td>CPU(%)</td><td>内存(%)</td><td>下载带宽</td><td>上传带宽</td><td>最后统计日期</td></tr>`
            data.forEach(items => {
              vm.tableData.push({
                id: items.id || '',
                name: items.name || '',
                hostname: items.hostname || '',
                owner: items.owner || '',
                instancetype: items.instancetype || '',
                inip: items.inip || '',
                exip: items.exip || '',
                type: items.type || '',
                status: items.status || '',
                lowcnt: items.lowcnt || '',
                cpu: items.cpu || '',
                mem: items.mem || '',
                netin: vm.keepDecimal(items.netin),
                netout: vm.keepDecimal(items.netout),
                date: items.date || ''
              })
            })
          } else {
            const trElements = vm.downloadTitle.map(item => `<td>${item}</td>`);
            vm.exportDownloadStr = `<tr>${trElements.join('')}</tr>`
            data.forEach(item => {
              const newData = {}
              vm.downloadTitle.forEach(cItem => {
                newData[cItem] = item[cItem]
              })
              vm.tableData.push(newData)
            })
          }
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

        vm.getUserInfo = function () {
          $http.get('/api/connector/connectorx/sso/userinfo').success(function (data) {
            vm.userInfo = data
          });
        }
        vm.getUserInfo();

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
                vm.markHashReload();
              } else {
                swal({ title: '操作失败', text: data.info, type: 'error' });
              }
            });
          });
        }

        vm.markHashReload = function ()  {
          $http.get(`/api/agent/nodelow/mark/${vm.treeid}` ).success(function(data){
            if (data.stat) {
              vm.hashMarkData = Object.keys(data.data)
            }
          })
        }
        vm.markHashReload()

        vm.handleChange = function () {
          const selectData = JSON.parse(JSON.stringify(vm.selectData))
          if (vm.markSelected === 'all') {
            vm.dealWithData(selectData.slice().reverse(), $scope.selectTab.id)
            vm.dataTable = new ngTableParams({count:20}, {counts:[],data:selectData.reverse()});
          } else if (vm.markSelected === 'computed') {
            let computedData = []
            if ($scope.selectTab.id === 'compute') {
              computedData = selectData.filter(item => vm.hashMarkData.includes(item.ip))
            }else {
              computedData = selectData.filter(item => vm.hashMarkData.includes(item['实例ID']))
            }
            vm.dealWithData(computedData.slice().reverse(), $scope.selectTab.id)
            vm.dataTable = new ngTableParams({count:20}, {counts:[],data:computedData.reverse()});
          } else if (vm.markSelected === 'undone') {
            let undonedData = []
            if ($scope.selectTab.id === 'compute') {
              undonedData = selectData.filter(item => vm.hashMarkData.includes(item.ip))
            }else {
              undonedData = selectData.filter(item => vm.hashMarkData.includes(item['实例ID']))
            }
            vm.dealWithData(undonedData.slice().reverse(), $scope.selectTab.id)
            vm.dataTable = new ngTableParams({count:20}, {counts:[],data:undonedData.reverse()});
          }
        }

        vm.handleTabChange =function (value) {
          $scope.selectTab = value
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
      const selectResourceArr = []
      angular.forEach(vm.checkboxes.items, function (value, key) {
        if (value) {
          selectResourceArr.push(key)
        }
      });
      const selectResDetail = vm.checkDataList.filter(item => selectResourceArr.find(cItem => cItem === item.name));
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
          tableReload: function () { return vm.tableReload }
        }
      });
    }

    $scope.$watch('selectTab', function () {
      if ($scope.selectTab && $scope.selectTab.id) {
        vm.checkboxes = {
          checked: false,
          items: {},
        };
        vm.monitorDataCardList = [
          {
            name: 'C3T.利用率低',
            status: 'low',
            count: 0,
            color: 'red'
          },
          {
            name: 'C3T.警告',
            status: 'warn',
            count: 0,
            color: '#f6bb42'
          },
          {
            name: 'C3T.正常',
            status: 'normal',
            count: 0,
            color: 'green'
          },
          {
            name: 'C3T.未知',
            status: 'unkown',
            count: 0,
            color: '#000'
          },
        ]
        vm.getMarkData();
      }
    })

    // 监听全选checkbox
    $scope.$watch(function () { return vm.checkboxes.checked }, function (value) {
      angular.forEach(vm.checkDataList, function (item, index, array) {
        vm.checkboxes.items[[array[index].name]] = value
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
        checked += (vm.checkboxes.items[array[index].name]) || 0;
        unchecked += (!vm.checkboxes.items[array[index].name]) || 0;
      });
      if (vm.checkDataList.length > 0 && ((unchecked == 0) || (checked == 0))) {
        vm.checkboxes.checked = (checked == vm.checkDataList.length);
      }
      vm.checkboxes.itemsNumber = checked
      angular.element(document.getElementsByClassName("select-all")).prop("indeterminate", (checked != 0 && unchecked != 0));
    }, true);
    }
})();
