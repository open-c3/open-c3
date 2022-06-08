(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateNamespaceAuthController', KubernetesCreateNamespaceAuthController);

    function KubernetesCreateNamespaceAuthController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace, clusterinfo, reload ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.namespacetemp = namespace;
        vm.namespace = namespace;
        vm.user;
        vm.auth = 'r';

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.addauth = function(){
            vm.loadover = false;
            var d = {
                "ticketid":  ticketid,
                "namespace": vm.namespace,
                "user": vm.user,
                "auth": vm.auth,
            };

            $http.post("/api/ci/kubernetes/namespaceauth/" + ticketid , d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   reload( vm.name );
                   vm.cancel();
                } else { 
                   swal({ title:'操作失败', text: data.info, type:'error' });
                }
            });
        };

        vm.reload = function() {
            $http.get("/api/ci/v2/kubernetes/namespace?ticketid=" + ticketid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.namespaces = response.data.data; 
                    }else {
                        toastr.error( "获取集群NAMESPACE数据失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取集群NAMESPACE数据失败: " + response.status )
                });
        };
        vm.reload();

    }
})();
