(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesEditYamlController', KubernetesEditYamlController);

    function KubernetesEditYamlController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/kubernetes/app/yaml?ticketid=" + ticketid + '&type=' + type + '&name=' + name + '&namespace=' + namespace  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.yaml = data.data;

                   vm.loadover = true;
                } else { 
                    toastr.error("加载配置失败:" + data.info)
                }
            });
        };

        vm.reload();

        vm.apply = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "type": type,
                "name": name,
                "namespace": namespace,
                "yaml": vm.yaml,
            };
            $http.post("/api/ci/kubernetes/app/apply", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.cancel();
                } else { 
                    toastr.error("更新配置失败:" + data.info)
                }
            });
        };

    }
})();
