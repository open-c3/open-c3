(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesDescribeController', KubernetesDescribeController);

    function KubernetesDescribeController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/app/describe?ticketid=" + ticketid + '&type=' + type + '&name=' + name + '&namespace=' + namespace  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.describe = data.data;
                    vm.loadover = true;
                } else { 
                    toastr.error("加载失败:" + data.info)
                }
            });
        };

        vm.reload();

     
    }
})();
