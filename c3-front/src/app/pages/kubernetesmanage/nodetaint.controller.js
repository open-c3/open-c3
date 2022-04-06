(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesNodeTaintController', KubernetesNodeTaintController);

    function KubernetesNodeTaintController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

vm.neweffect = 'NoSchedule';

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/node/taint?ticketid=" + ticketid + '&nodename=' + name  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.dataTable = new ngTableParams({count:10}, {counts:[],data:data.data});
                    vm.loadover = true;
                } else { 
                    toastr.error("加载失败:" + data.info)
                }
            });
        };

        vm.reload();

        vm.createTaint = function(){
            $http.post("/api/ci/v2/kubernetes/node/taint?ticketid=" + ticketid + '&nodename=' + name + "&key=" + vm.newkey + "&value=" + vm.newvalue + "&effect=" + vm.neweffect  ).success(function(data){
                if(data.stat == true) 
                { 
vm.newkey = "";
vm.newvalue ="";
                    vm.reload();
                } else { 
                    toastr.error("添加失败:" + data.info)
                }
            });
        };

        vm.deleteTaint = function( key, effect ){
            $http.delete("/api/ci/v2/kubernetes/node/taint?ticketid=" + ticketid + '&nodename=' + name + "&key=" + key + "&effect=" + effect  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.reload();
                } else { 
                    toastr.error("删除失败:" + data.info)
                }
            });
        };

    }
})();
