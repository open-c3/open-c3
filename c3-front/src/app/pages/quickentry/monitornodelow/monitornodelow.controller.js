(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonitorNodeLowController', MonitorNodeLowController);

    function MonitorNodeLowController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, genericService, $scope, $injector, $sce ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.userInfo = {}
        vm.markSelected = 'all'
        vm.markSelectOption = [
          {value: 'all', label: '全部'},
          {value: 'computed', label: '已标记'},
          {value: 'undone', label: '未标记'},
        ]
        vm.hashMarkData = []
        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });


        $scope.count1 = 0;
        $scope.count2 = 0;
        $scope.count3 = 0;
        $scope.count4 = 0;

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

           vm.dataTable = new ngTableParams({count:20}, {counts:[],data:vm.tempdata.reverse()});
        }

        vm.reload = function(){
            vm.loadover = false;

            $scope.count1 = 0;
            $scope.count2 = 0;
            $scope.count3 = 0;
            $scope.count4 = 0;

            $http.get('/api/agent/nodelow/' + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.dataTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.selectData = data.data
                    vm.allData = data.data;

                    angular.forEach(data.data, function (data, index) {
                        if( data.status == 'low' )
                        {
                            $scope.count1 = $scope.count1 + 1
                        }
                        if( data.status == 'warn' )
                        {
                            $scope.count2 = $scope.count2 + 1
                        }
                        if( data.status == 'normal' )
                        {
                            $scope.count3 = $scope.count3 + 1
                        }
                        if( data.status == 'unkown' )
                        {
                            $scope.count4 = $scope.count4 + 1
                        }
                    });

                    vm.loadover = true;
                } else { 
                    toastr.error( "加载数据失败:" + data.info )
                }
            });
        };

        vm.reload();

        vm.download = function () {
          let str = `<tr><td>编号</td><td>主机名</td><td>名称</td><td>Owner</td><td>资源类型</td><td>内网IP</td><td>外网IP</td><td>资源类型</td><td>状态</td><td>低利用率天数/14天</td><td>CPU(%)</td><td>内存(%)</td><td>下载带宽</td><td>上传带宽</td><td>最后统计日期</td></tr>`
          var jsonData = vm.allData;
          if( vm.stat != '' )
          {
              jsonData = vm.tempdata;
          }

          jsonData.forEach((items,i) => {
            let newItem = {
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
              netin: items.netin? 
                      1048576 < items.netin? 
                        `${items.netin / 1048576}Mb/s` :
                          1024 < items.netin && items.netin <= 1048576 ? 
                            `${items.netin / 1024}Kb/s` :
                            items.netin <= 1024? 
                              `${items.netin}b/s`: ''
                      :'',
               netout: items.netout? 
                      1048576 < items.netout? 
                        `${items.netout / 1048576}Mb/s` :
                          1024 < items.netout && items.netout <= 1048576 ? 
                            `${items.netout / 1024}Kbs` :
                            items.netout <= 1024? 
                              `${items.netout}b/s`: ''
                      :'',
              date: items.date || ''
            }
            str += '<tr>'
            for (let item in Object.assign({}, newItem)) {
              if (item !== '$$hashKey') {
                let cellvalue = newItem[item] || ''
                str += `<td style="mso-number-format:'\@';">${cellvalue}</td>`
                // str+=`<td>${cellvalue}</td>`;
              }
            }
            str += '</tr>'
          })
          const worksheet = '导出结果'
          const uri = 'data:application/vnd.ms-excel;base64,'
          const template = `<html xmlns:o="urn:schemas-microsoft-com:office:office"
            xmlns:x="urn:schemas-microsoft-com:office:excel"
            xmlns="http://www.w3.org/TR/REC-html40">
            <head><!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet>
            <x:Name>${worksheet}</x:Name>
            <x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions></x:ExcelWorksheet>
            </x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]-->
            </head><body><table>${str}</table></body></html>`
          function base64(s) {
            return window.btoa(unescape(encodeURIComponent(s)))
          }
          window.location.href = uri + base64(template)
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
                vm.reload();
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
            vm.dataTable = new ngTableParams({count:20}, {counts:[],data:selectData.reverse()});
          } else if (vm.markSelected === 'computed') {
            const computedData = selectData.filter(item => vm.hashMarkData.includes(item.ip))
            console.log('computedData', computedData)
            vm.dataTable = new ngTableParams({count:20}, {counts:[],data:computedData.reverse()});
          } else if (vm.markSelected === 'undone') {
            const undonedData = selectData.filter(item => !vm.hashMarkData.includes(item.ip))
            vm.dataTable = new ngTableParams({count:20}, {counts:[],data:undonedData.reverse()});
          }
        }
    }
})();
