(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DeviceDataController', DeviceDataController);

    function DeviceDataController($state, $http, $scope, ngTableParams, $uibModal, treeService ) {
        var vm = this;

        treeService.sync.then(function(){      // when the tree was success.
            vm.nodeStr = treeService.selectname();  // get tree name
        });

        vm.showfilter = 0;

        vm.treeid  = $state.params.treeid;
        vm.type    = $state.params.type;
        vm.subtype = $state.params.subtype;
        vm.grepdata = {};
        vm.selectedtimemachine = $state.params.timemachine;
        vm.timemachine = [];

        vm.filter = [];
        vm.filterdata = {};
        vm.reload = function () {
            vm.loadover = false;
            $http.post('/api/agent/device/data/' + vm.type + '/' + vm.subtype + '/' + vm.treeid, { "grepdata": vm.grepdata, "timemachine": vm.selectedtimemachine } ).success(function(data){
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

        vm.reset = function () {
            vm.grepdata = {};
            vm.reload();
        };

        vm.showdetail = function (uuid, type, subtype ) {
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
                    type: function () {return type},
                    subtype: function () {return subtype},
                    treeid: function () {return vm.treeid},
                    name: function () {return name},
                    homereload: function () {return vm.reload},
                    selectedtimemachine: function () {return vm.selectedtimemachine},
                }
            });
        };

    }
})();
