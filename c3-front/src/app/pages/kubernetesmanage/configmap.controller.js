(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesConfigMapController', KubernetesConfigMapController);

    function KubernetesConfigMapController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/configmap?ticketid=" + ticketid ).success(function(data){
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
 
        vm.deleteApp = function (type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/deleteapp.html',
                controller: 'KubernetesDeleteAppController',
                controllerAs: 'kubernetesdeleteapp',
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
                    clusterinfo: function () {return clusterinfo},
                }
            });
        };

        vm.describe = function (type,name,namespace) {
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
                    ticketid: function () {return clusterinfo.id},
                }
            });
        };

        vm.edityaml = function (type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/edityaml.html',
                controller: 'KubernetesEditYamlController',
                controllerAs: 'kubernetesedityaml',
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
                }
            });
        };

        vm.createConfigMap = function (namespace,name) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/createconfigmap.html',
                controller: 'KubernetesCreateConfigMapController',
                controllerAs: 'kubernetescreateconfigmap',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    ticketid: function () {return clusterinfo.id},
                    clusterinfo: function () {return clusterinfo},
                    namespace: function () {return namespace},
                    name: function () {return name},
                }
            });
        };

    }
})();
