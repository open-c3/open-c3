(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesSetImageController', KubernetesSetImageController);

    function KubernetesSetImageController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace,image, container ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.image = image;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.setimage = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "type": type,
                "name": name,
                "namespace": namespace,
                "image": vm.image,
                "container": container,
            };
            $http.post("/api/ci/kubernetes/app/setimage", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.cancel();
                } else { 
                    toastr.error("升级应用失败:" + data.info)
                }
            });
        };

     
    }
})();
