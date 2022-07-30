(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DeviceDataController', DeviceDataController);

    function DeviceDataController($state, $http, $scope, ngTableParams) {
        var vm = this;

        vm.treeid  = $state.params.treeid;
        vm.type    = $state.params.type;
        vm.subtype = $state.params.subtype;

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/agent/device/data/' + vm.type + '/' + vm.subtype ).success(function(data){
                if (data.stat){
                    vm.dataTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取数据失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

    }
})();
