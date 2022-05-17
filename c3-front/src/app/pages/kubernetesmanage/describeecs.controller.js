(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesDescribeEcsController', KubernetesDescribeEcsController);

    function KubernetesDescribeEcsController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace, data ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.post("/api/ci/v2/kubernetes/app/describe/ecs?ticketid=" + data.ticketid, { "cmd": data.cmd } ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.describe = data.data.describe;
                    vm.taskdefinition = data.data.taskdefinition;
                    vm.dataTable = new ngTableParams({count:10}, {counts:[],data:data.data.deployments});
                    vm.loadover = true;
                } else { 
                    toastr.error("加载失败:" + data.info)
                }
            });
        };

        vm.reload();
    }
})();
