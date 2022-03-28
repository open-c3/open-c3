(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesK8sbackupController', KubernetesK8sbackupController);

    function KubernetesK8sbackupController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo, namespace ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.clusterinfo = clusterinfo;
        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/k8sbackup?ticketid=" + ticketid + "&namespace=" + namespace ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.nodeTable = new ngTableParams({count:25}, {counts:[],data:data.data.reverse()});
                } else { 
                    toastr.error("加载备份列表失败:" + data.info)
                }
            });

        };
        vm.reload();
 
        vm.downloadfile = function (name) {
            $http.get( "/api/ci/kubernetes/k8sbackup/download?ticketid=" + ticketid + "&name=" + name ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        var downloadAddr = window.location.protocol + "//"+window.location.host+"/api/job/download/";
                         window.open(downloadAddr+response.data.data, '_blank')
                    }else {
                        swal({ title:'下载失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response ){
                    toastr.error( "获取下载地址失败："+response.status)
                });
        };

    }
})();
