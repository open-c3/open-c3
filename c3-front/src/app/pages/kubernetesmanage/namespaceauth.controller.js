(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesNamespaceAuthController', KubernetesNamespaceAuthController);

    function KubernetesNamespaceAuthController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo, namespace ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.namespace = namespace;
        vm.clusterinfo = clusterinfo;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/kubernetes/namespaceauth/" + ticketid + "?namespace=" + namespace ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.nodeTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                } else { 
                    if( data.info.indexOf("no auth") >= 0  )
                    {
                        swal({ title:'没有权限', text: "您没有该操作权限", type:'error' });
                        vm.cancel();
                        return;
                    }
                    toastr.error("加载权限表格失败:" + data.info)
                }
            });
        };
        vm.reload();
 
        vm.deleteAuth = function(id){
            vm.loadover = false;
            $http.delete("/api/ci/kubernetes/namespaceauth/" + ticketid + "/" + id ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.reload();
                } else { 
                    toastr.error("删除权限失败:" + data.info)
                }
            });
        };

        vm.createNamespaceAuth = function (type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/createnamespaceauth.html',
                controller: 'KubernetesCreateNamespaceAuthController',
                controllerAs: 'kubernetescreatenamespaceauth',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    namespace: function () {return namespace},
                    ticketid: function () {return clusterinfo.id},
                    clusterinfo: function () {return clusterinfo},
                    reload: function () {return vm.reload},
                }
            });
        };

    }
})();
