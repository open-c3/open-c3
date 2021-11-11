(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AssignmentCommitController', AssignmentCommitController);

    function AssignmentCommitController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, postData, homecancel ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.postData = postData;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.commit = function(){
//            var pd = {
//                "type": "kubernetes",
//                "name": "修改副本数",
//                "handler": "open-c3",
//                "url": "/api/ci/kubernetes/app/setreplicas",
//                "method": "POST",
//                "submit_reason": "balabala...",
//                "remarks": "balabala...",
//                "data": {
//                    "ticketid": 'ticketid',
//                    "type": 'type',
//                    "name": 'name',
//                    "namespace": 'namespace',
//                    "replicas": 'vm.replicas',
//                }
//            };
            $http.post("/api/ci/assignment", postData  ).success(function(data){
                if(data.stat == true)
                {
                    vm.cancel();
                    homecancel();
                    swal({ title:'提交操作协助申请成功', text: '请到个人协助操作页面查看历史', type:'success' });
                } else {
                    swal({ title:'提交失败', text: data.info, type:'success' });
                }
            });
        };

    }
})();
