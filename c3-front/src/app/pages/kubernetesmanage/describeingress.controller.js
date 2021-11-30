(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesDescribeIngressController', KubernetesDescribeIngressController);

    function KubernetesDescribeIngressController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/app/describeingress?ticketid=" + ticketid + '&type=' + type + '&name=' + name + '&namespace=' + namespace  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.describe = data.data.describe;
                    vm.serviceTable = new ngTableParams({count:10}, {counts:[],data:data.data.service});
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

        vm.describexxservice = function (type,name) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/describeservice.html',
                controller: 'KubernetesDescribeServiceController',
                controllerAs: 'kubernetesdescribeservice',
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
