(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesNodeController', KubernetesNodeController);

    function KubernetesNodeController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.cordon = function(node,cordon){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "cordon": cordon,
                "node": node,
            };
            $http.post("/api/ci/v2/kubernetes/node/cordon", d  ).success(function(data){
                if(data.stat == true) 
                {
                    vm.loadover = true;
                    vm.reload();
                } else {
                    toastr.error("操作失败:" + data.info)
                }
            });
        };

        vm.drain = function(node){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "node": node,
            };
            $http.post("/api/ci/v2/kubernetes/node/drain", d  ).success(function(data){
                if(data.stat == true) 
                {
                    vm.loadover = true;
                    toastr.success("操作成功:" + data.info)
                    vm.reload();
                } else {
                    toastr.error("操作失败:" + data.info)
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
                    ticketid: function () {return ticketid},
                }
            });
        };


        vm.nodetaint = function (type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/nodetaint.html',
                controller: 'KubernetesNodeTaintController',
                controllerAs: 'kubernetesnodetaint',
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

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/node?ticketid=" + ticketid ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.nodeTable = new ngTableParams({count:10}, {counts:[],data:data.data});
                } else { 
                    if( data.info.indexOf("no auth") >= 0  )
                    {
                        swal({ title:'没有权限', text: "您没有该操作权限", type:'error' });
                        vm.cancel();
                        return;
                    }
                    toastr.error("加载集群节点信息失败:" + data.info)
                }
            });
        };
        vm.reload();
 
    }
})();
