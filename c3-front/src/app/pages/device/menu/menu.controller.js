(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DeviceMenuController', DeviceMenuController);

    function DeviceMenuController($state, $http, $scope, ngTableParams) {
        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.menu = {};

        vm.reload = function () {
            vm.loadover = false;
            $http.get( '/api/agent/device/menu/' + vm.treeid ).success(function(data){
                if (data.stat){
                    vm.menu = data.data;
                    vm.loadover = true;
                }else {
                    swal({ title:'获取菜单失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

        vm.gotosubtype = function (type, subtype) {
            $state.go('home.device.data', {treeid:vm.treeid, type: type, subtype: subtype });
        };

        vm.openNewWindow = function()
        {
            var newurl = '/third-party/monitor/prometheus/graph?g0.expr=c3_cmdb_resources_count&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=3h';
            window.open( newurl, '_blank')
        }
    }
})();
