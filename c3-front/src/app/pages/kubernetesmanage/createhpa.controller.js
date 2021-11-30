(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateHpaController', KubernetesCreateHpaController);

    function KubernetesCreateHpaController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace, clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.name = name;
        vm.type = type;

        vm.min = 1;
        vm.max = 3;
        vm.cpu = 60;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.add = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "type": type,
                "name": name,
                "namespace": namespace,
                "cpu": vm.cpu,
                "min": vm.min,
                "max": vm.max,
            };

            $http.post("/api/ci/v2/kubernetes/hpa/create", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.cancel();
                } else { 
                   swal({ title:'操作失败', text: data.info, type:'error' });
                }
            });
        };

        vm.assignment = function () {
            var postData = {
                "type": "kubernetes",
                "name": "创建HPA",
                "handler": clusterinfo.create_user,
                "url": "/api/ci/v2/kubernetes/hpa/create",
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name + ";\n命名空间:"+ namespace + ";\n类型:" + type + ";\n名称:" + name + ";\ncpu百分比:" + vm.cpu + ";\n最小副本数:" + vm.min + ";\n最大副本数:" + vm.max,
                "data": {
                    "ticketid": ticketid,
                    "type": type,
                    "name": name,
                    "namespace": namespace,
                    "cpu": vm.cpu,
                    "min": vm.min,
                    "max": vm.max,
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
