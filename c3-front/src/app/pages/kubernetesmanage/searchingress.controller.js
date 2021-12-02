(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesSearchIngressController', KubernetesSearchIngressController);

    function KubernetesSearchIngressController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/app/ingress/dump" ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.nodeTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                } else { 
                    toastr.error("加载ingress失败:" + data.info)
                }
            });
        };
        vm.reload();
 
        vm.describeingress = function (ticketid, type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/describeingress.html',
                controller: 'KubernetesDescribeIngressController',
                controllerAs: 'kubernetesdescribeingress',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    namespace: function () {return namespace},
                    ticketid: function () {return ticketid},
                }
            });
        };

    }
})();
