(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DeviceDataDetailController', DeviceDataDetailController);

    function DeviceDataDetailController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, uuid, $scope, $injector, treeid , type, subtype, homereload ) {

        var vm = this;

        vm.treeid = treeid;
        vm.type = type;
        vm.subtype = subtype;
        vm.uuid = uuid;
        vm.treenamecol = '';

        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        vm.data = [];
        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/device/detail/' + type + '/' + subtype +'/' + vm.treeid + '/' + uuid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.data = data.data;
                    vm.treenamecol = data.treenamecol;

                    vm.loadover = true;
                } else { 
                    toastr.error("加载数据失败:" + data.info)
                }
            });
        };

        vm.bindtree = function( newtree ){
            vm.loadover = false;
            $http.get('/api/agent/device/tree/bind/' + type + '/' + subtype +'/' + vm.uuid + '/' + newtree ).success(function(data){
                if(data.stat == true) 
                { 
                    toastr.success("操作完成");
                    vm.cancel();
                    homereload();
                } else { 
                    toastr.error("操作失败:" + data.info)
                }
            });
        };
 
        vm.reload();
    }
})();
