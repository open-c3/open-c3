(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesSetReplicasController', KubernetesSetReplicasController);

    function KubernetesSetReplicasController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace, replicas, clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.replicas = replicas;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.setreplicas = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "type": type,
                "name": name,
                "namespace": namespace,
                "replicas": vm.replicas,
            };
            $http.post("/api/ci/v2/kubernetes/app/setreplicas", d  ).success(function(data){
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
                "name": "修改Deployment副本数",
                "handler": clusterinfo.create_user,
                "url": "/api/ci/v2/kubernetes/app/setreplicas",
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name + ";\n命名空间:"+ namespace + ";\n类型:" + type + ";\n名称:" + name +";\n原副本数:" + replicas + "=> 新副本数:" + vm.replicas,
                "data": {
                    "ticketid": ticketid,
                    "type": type,
                    "name": name,
                    "namespace": namespace,
                    "replicas": vm.replicas,
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
