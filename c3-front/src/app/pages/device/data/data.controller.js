(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DeviceDataController', DeviceDataController);

    function DeviceDataController($state, $http, $scope, ngTableParams, $uibModal) {
        var vm = this;

        vm.treeid  = $state.params.treeid;
        vm.type    = $state.params.type;
        vm.subtype = $state.params.subtype;
        vm.grepdata = {};

        vm.filter = [];
        vm.filterdata = {};
        vm.reload = function () {
            vm.loadover = false;
            $http.post('/api/agent/device/data/' + vm.type + '/' + vm.subtype + '/' + vm.treeid, { "grepdata": vm.grepdata } ).success(function(data){
                if (data.stat){
                    vm.dataTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                    vm.filter = data.filter;
                    vm.filterdata = data.filterdata;
                    vm.loadover = true;
                }else {
                    swal({ title:'获取数据失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

        vm.reset = function () {
            vm.grepdata = {};
            vm.reload();
        };

        vm.showdetail = function (uuid) {
            $uibModal.open({
                templateUrl: 'app/pages/device/data/detail.html',
                controller: 'DeviceDataDetailController',
                controllerAs: 'devicedatadetail',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    getGroup: function () {return vm.getGroupInfo},
                    uuid: function () {return uuid},
                    type: function () {return vm.type},
                    subtype: function () {return vm.subtype},
                    treeid: function () {return vm.treeid},
                    name: function () {return name},
                    homereload: function () {return vm.reload},
                }
            });
        };

    }
})();
