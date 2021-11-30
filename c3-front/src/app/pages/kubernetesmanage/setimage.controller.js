(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesSetImageController', KubernetesSetImageController);

    function KubernetesSetImageController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace,image, container, clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.image = image;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.setimage = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "type": type,
                "name": name,
                "namespace": namespace,
                "image": vm.image,
                "container": container,
            };
            $http.post("/api/ci/v2/kubernetes/app/setimage", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.cancel();
                } else { 
                    toastr.error("升级应用失败:" + data.info)
                }
            });
        };

        vm.assignment = function () {
            var postData = {
                "type": "kubernetes",
                "name": "修改Deployment镜像",
                "handler": clusterinfo.create_user,
                "url": "/api/ci/v2/kubernetes/app/setimage",
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name + ";\n命名空间:"+ namespace + ";\n类型:" + type + ";\n名称:" + name +";\n原镜像地址:" + image + ";\n新镜像地址:" + vm.image,
                "data": {
                    "ticketid": ticketid,
                    "type": type,
                    "name": name,
                    "namespace": namespace,
                    "image": vm.image,
                    "container": container,
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
