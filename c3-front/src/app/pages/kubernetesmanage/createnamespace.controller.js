(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateNamespaceController', KubernetesCreateNamespaceController);

    function KubernetesCreateNamespaceController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo, homereload ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.namespace;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.create = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "namespace": vm.namespace,
            };

            $http.post("/api/ci/v2/kubernetes/namespace", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.cancel();
                   homereload();
                } else { 
                   swal({ title:'操作失败', text: data.info, type:'error' });
                }
            });
        };

        vm.assignment = function () {
            var postData = {
                "type": "kubernetes",
                "name": "创建NAMESPACE",
                "handler": clusterinfo.create_user,
                "url": "/api/ci/v2/kubernetes/namespace",
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name + ";\n命名空间:" + vm.namespace,
                "data": {
                    "ticketid": ticketid,
                    "namespace": vm.namespace,
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
