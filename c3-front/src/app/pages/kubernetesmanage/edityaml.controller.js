(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesEditYamlController', KubernetesEditYamlController);

    function KubernetesEditYamlController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace,clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/app/yaml?ticketid=" + ticketid + '&type=' + type + '&name=' + name + '&namespace=' + namespace  ).success(function(data){
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
            $http.post("/api/ci/v2/kubernetes/app/apply", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.cancel();
                } else { 
                    toastr.error("更新配置失败:" + data.info)
                }
            });
        };

        vm.assignment = function () {
            var postData = {
                "type": "kubernetes",
                "name": "修改Deployment配置",
                "handler": "",
                "url": "/api/ci/v2/kubernetes/app/apply",
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name + ";\n命名空间:"+ namespace + ";\n类型:" + type + ";\n名称:" + name +";\n新配置:\n" + vm.yaml,
                "data": {
                    "ticketid": ticketid,
                    "type": type,
                    "name": name,
                    "namespace": namespace,
                    "yaml": vm.yaml,
                },
            };

            $uibModal.open({
                templateUrl: 'app/pages/assignment/assignmentcommit.html',
                controller: 'AssignmentCommitController',
                controllerAs: 'assignmentcommit',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    postData: function () {return postData},
                    homecancel: function () {return vm.cancel},
                }
            });
        };


    }
})();
