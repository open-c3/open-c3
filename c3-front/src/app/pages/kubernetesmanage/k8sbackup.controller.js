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
            $http.get("/api/ci/v2/kubernetes/k8sbackup?ticketid=" + ticketid ).success(function(data){
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
 
        vm.downloadfile = function (name, type ) {
            $http.get( "/api/ci/kubernetes/k8sbackup/download" + type + "?ticketid=" + ticketid + "&name=" + name ).then(
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

        vm.backup = function(){
            $http.post("/api/ci/v2/kubernetes/k8sbackup?ticketid=" + ticketid ).success(function(data){
                if(data.stat == true) 
                { 
                    swal({ title:'备份任务已提交', text: "备份可能需要几分钟，过一会在回来查看结果吧!!!", type:'success' });
                } else { 
                    swal({ title:'提交成功', text: data.info, type:'error' });
                }
            });

        };

    }
})();
