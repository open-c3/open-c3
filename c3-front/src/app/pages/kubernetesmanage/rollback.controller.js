(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesRollbackController', KubernetesRollbackController);

    function KubernetesRollbackController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace, clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.version = '';

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });


        vm.rollback = function(version){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "type": type,
                "name": name,
                "namespace": namespace,
                "version": version,
            };
            $http.post("/api/ci/kubernetes/app/rollback", d  ).success(function(data){
                if(data.stat == true) 
                {
                    vm.loadover = true;
                    vm.cancel();
                } else {
                    toastr.error("回滚操作失败:" + data.info)
                }
            });
        };

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/kubernetes/app/rollback?type=" + type + '&namespace=' + namespace + '&name=' + name +'&ticketid=' + ticketid ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.versionTable = new ngTableParams({count:10}, {counts:[],data:data.data});
                } else { 
                    toastr.error("加载回滚版本信息失败:" + data.info)
                }
            });
        };
        vm.reload();

        vm.assignment = function (version,image) {
            var postData = {
                "type": "kubernetes",
                "name": "修改Deployment镜像",
                "handler": "",
                "url": "/api/ci/kubernetes/app/rollback",
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name + ";\n命名空间:"+ namespace + ";\n类型:" + type + ";\n名称:" + name +";\n镜像地址:" + image + ";\n版本编号:" + version,
                "data": {
                    "ticketid": ticketid,
                    "type": type,
                    "name": name,
                    "namespace": namespace,
                    "version": version,
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
