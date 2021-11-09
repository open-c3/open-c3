(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesSetReplicasController', KubernetesSetReplicasController);

    function KubernetesSetReplicasController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace,replicas ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.replicas = replicas;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.setreplicas = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "type": type,
                "name": name,
                "namespace": namespace,
                "replicas": vm.replicas,
            };
            $http.post("/api/ci/kubernetes/app/setreplicas", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.cancel();
                } else { 
                    toastr.error("操作失败:" + data.info)
                }
            });
        };

     
    }
})();
