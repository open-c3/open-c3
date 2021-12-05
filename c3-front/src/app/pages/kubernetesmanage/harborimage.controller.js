(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesHarborImageController', KubernetesHarborImageController);

    function KubernetesHarborImageController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, homereload ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/harbor/repository?ticketid=" + ticketid ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.nodeTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                } else { 
                    toastr.error("加载secret信息失败:" + data.info)
                }
            });

        };
        vm.reload();
 
        vm.selectRepo = function (repo) {
            homereload(repo);
            vm.cancel();
        };

    }
})();
