(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateHpaController', KubernetesCreateHpaController);

    function KubernetesCreateHpaController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace, clusterinfo, namespaces, deployments, daemonsets, replicasets ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.name = name;
        vm.type = type;
        vm.namespace = namespace;

        vm.selectnamespace = 1;
        if( vm.namespace )
        {
            vm.selectnamespace = 0;
        }
        vm.namespaces = namespaces;

        vm.full = 0;
        if( vm.name && vm.type && vm.namespace )
        {
            vm.full = 1;
        }
        if( !vm.type )
        {
            vm.type = "deployment";
        }
        vm.min = 1;
        vm.max = 3;
        vm.cpu = 60;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.change = function(){
            console.log("change", vm.type, vm.namespace )
            vm.name = "";
            vm.names = [];
            if( !( vm.type && vm.namespace ))
            {
                vm.names = [];
                return;
            }

            if( vm.type === "deployment" )
            {
                angular.forEach(deployments, function (v, k) {
                    if( vm.namespace === v.NAMESPACE )
                    {
                        vm.names.push( v.INAME )
                    }
                });
            }

            if( vm.type === "daemonset" )
            {
                angular.forEach(daemonsets, function (v, k) {
                    if( vm.namespace === v.NAMESPACE )
                    {
                        vm.names.push( v.INAME )
                    }
                });
            }

            if( vm.type === "replicaset" )
            {
                angular.forEach(replicasets, function (v, k) {
                    if( vm.namespace === v.NAMESPACE )
                    {
                        vm.names.push( v.INAME )
                    }
                });
            }

        }
        if(vm.full !== 1 )
        {
            vm.change();
        }
//
        vm.add = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "type": vm.type,
                "name": vm.name,
                "namespace": vm.namespace,
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
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name + ";\n命名空间:"+ vm.namespace + ";\n类型:" + vm.type + ";\n名称:" + vm.name + ";\ncpu百分比:" + vm.cpu + ";\n最小副本数:" + vm.min + ";\n最大副本数:" + vm.max,
                "data": {
                    "ticketid": ticketid,
                    "type": vm.type,
                    "name": vm.name,
                    "namespace": vm.namespace,
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
