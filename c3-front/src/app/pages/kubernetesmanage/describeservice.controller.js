(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesDescribeServiceController', KubernetesDescribeServiceController);

    function KubernetesDescribeServiceController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/app/describeservice?ticketid=" + ticketid + '&type=' + type + '&name=' + name + '&namespace=' + namespace  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.describe = data.data.describe;
                    vm.deploymentTable = new ngTableParams({count:10}, {counts:[],data:data.data.table.deployment});
                    vm.replicasetTable = new ngTableParams({count:10}, {counts:[],data:data.data.table.replicaset});
                    vm.podTable = new ngTableParams({count:10}, {counts:[],data:data.data.table.pod});
                    vm.loadover = true;
                } else { 
                    toastr.error("加载失败:" + data.info)
                }
            });
        };

        vm.reload();
        vm.describexx = function (type,name) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/describe.html',
                controller: 'KubernetesDescribeController',
                controllerAs: 'kubernetesdescribe',
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

        vm.describexxdeployment = function (type,name) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/describedeployment.html',
                controller: 'KubernetesDescribeDeploymentController',
                controllerAs: 'kubernetesdescribedeployment',
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

        vm.openOneTab = function (pod, type) {
            var terminalAddr = window.location.protocol + "//" + window.location.host+"/api/ci/kubernetes/pod/shell";
            var s = "?namespace=" + namespace + '&name=' + pod.NAME + '&clusterid=' + ticketid + '&type=' + type + '&siteaddr=' + window.location.protocol + "//" + window.location.host;
            window.open(terminalAddr+s, '_blank')
        };

    }
})();
