(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DeviceMenuController', DeviceMenuController);

    function DeviceMenuController($state, $http, $scope, ngTableParams, treeService ) {
        var vm = this;
        vm.treeid = $state.params.treeid;

        treeService.sync.then(function(){      // when the tree was success.
            vm.nodeStr = treeService.selectname();  // get tree name
        });

        vm.menu = {};
        vm.selectedtimemachine = 'curr';
        vm.timemachine = [];

        vm.totalResources = {
          compute: 0,
          networking: 0,
          storage: 0,
          database: 0,
          domain: 0,
          others: 0
        }
        vm.reload = function () {
            vm.loadover = false;
            $http.get( '/api/agent/device/menu/' + vm.treeid + '?timemachine=' + vm.selectedtimemachine ).success(function(data){
                if (data.stat){
                    vm.menu = data.data;
                    vm.loadover = true;
                    let totalArr = JSON.parse(JSON.stringify(data.data))
                    for (let key in totalArr) {
                      vm.totalResources[key] = totalArr[key].map(item=> item.map(cItem => cItem[2]? cItem[2]: 0))
                    }
                    for (let key in  vm.totalResources) {
                      const initialValue = 0;
                      vm.totalResources[key] = vm.totalResources[key].flat(Infinity).reduce((acc, cur) => acc + cur,  initialValue)
                    }
                }else {
                    swal({ title:'获取菜单失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();
        vm.reloadtimemachine = function () {
            $http.get('/api/agent/device/timemachine' ).success(function(data){
                if (data.stat){
                    vm.timemachine = data.data;
                }else {
                    swal({ title:'获取时间机器列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reloadtimemachine();

        vm.gotosubtype = function (type, subtype) {
            $state.go('home.device.data', {treeid:vm.treeid, timemachine: vm.selectedtimemachine, type: type, subtype: subtype });
        };

        vm.openNewWindow = function( metrics, tab )
        {
            var newurl = '/third-party/monitor/prometheus/graph?g0.expr=' + metrics + '&g0.tab=' + tab + '&g0.stacked=0&g0.show_exemplars=0&g0.range_input=3h';
            window.open( newurl, '_blank')
        }
    }
})();
