(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateSecretController', KubernetesCreateSecretController);

    function KubernetesCreateSecretController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace, clusterinfo, reload ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.namespacetemp = namespace;
        vm.namespace = namespace;
        vm.name;
        vm.server;
        vm.username;
        vm.password;
        vm.email;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.deleteapp = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "namespace": vm.namespace,
                "name": vm.name,
                "server": vm.server,
                "username": vm.username,
                "password": vm.password,
                "email": vm.email,
            };

            $http.post("/api/ci/v2/kubernetes/secret/dockerconfigjson", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   reload( vm.name );
                   vm.cancel();
                } else { 
                   swal({ title:'操作失败', text: data.info, type:'error' });
                }
            });
        };

        vm.reload = function() {
            $http.get("/api/ci/v2/kubernetes/namespace?ticketid=" + ticketid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.namespaces = response.data.data; 
                    }else {
                        toastr.error( "获取集群NAMESPACE数据失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取集群NAMESPACE数据失败: " + response.status )
                });
        };
        vm.reload();

        vm.assignment = function () {
            var postData = {
                "type": "kubernetes",
                "name": "kubernetes secret create",
                "handler": clusterinfo.create_user,
                "url": "/api/ci/v2/kubernetes/secret/dockerconfigjson",
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name + ";\n命名空间:" + vm.namespace + ";\nsecret名称:"+ vm.name,
                "data": {
                    "ticketid": ticketid,
                    "namespace": vm.namespace,
                    "name": vm.name,
                    "server": vm.server,
                    "username": vm.username,
                    "password": vm.password,
                    "email": vm.email,
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
