(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('MonitorNodeLowDetailController', MonitorNodeLowDetailController);

    function MonitorNodeLowDetailController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, ip ) {

        var vm = this;
        vm.ip = ip;
        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/nodelow/detail/' + treeid + '/' + ip ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.dataTable = new ngTableParams({count:20}, {counts:[],data:data.data});
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载数据失败:" + data.info )
                }
            });
        };

        vm.reload();
    }
})();

