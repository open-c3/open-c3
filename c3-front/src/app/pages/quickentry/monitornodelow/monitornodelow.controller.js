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
            id: 'host',
            name: '主机低利用率'
          },
        ]
        $scope.selectTab = vm.lowUtilizationList[0];
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
            name: 'C3T.利用率低',
            status: 'unkown',
            count: 0,
            color: '#000'
          },

        ]
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

           vm.dealWithData(vm.tempdata.slice().reverse())
           vm.dataTable = new ngTableParams({count:20}, {counts:[],data:vm.tempdata.reverse()});
        }

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/nodelow/' + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.dealWithData(data.data.slice().reverse())
                    vm.dataTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.selectData = data.data
                    vm.allData = data.data;
                    vm.monitorDataCardList.map(item => item.count = data.data.filter(cItem => cItem.status === item.status).length)
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载数据失败:" + data.info )
                }
            });
        };

        vm.reload();

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

        vm.dealWithData = function (data) {
          vm.tableData = []
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
                    reload: function () { return vm.reload },
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
            vm.dealWithData(selectData.slice().reverse())
            vm.dataTable = new ngTableParams({count:20}, {counts:[],data:selectData.reverse()});
          } else if (vm.markSelected === 'computed') {
            const computedData = selectData.filter(item => vm.hashMarkData.includes(item.ip))
            vm.dealWithData(computedData.slice().reverse())
            vm.dataTable = new ngTableParams({count:20}, {counts:[],data:computedData.reverse()});
          } else if (vm.markSelected === 'undone') {
            const undonedData = selectData.filter(item => !vm.hashMarkData.includes(item.ip))
            vm.dealWithData(undonedData.slice().reverse())
            vm.dataTable = new ngTableParams({count:20}, {counts:[],data:undonedData.reverse()});
          }
        }

        vm.handleTabChange =function (value) {
          console.log('value', value)
          $scope.selectTab = value
          // vm.reload();
        }
    }
})();
