(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('QuickentryApprovalController', QuickentryApprovalController);

    function QuickentryApprovalController($scope,$filter, $state, $http,$window,$uibModal, $timeout, treeService, resoureceService, scriptId) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.postdata = { timeout: '86400', approver: '', cont: '审批一下吧', name: '', deployenv: 'always', action: 'always', batches: 'always', everyone: 'on', relaxed: 'off'  };
        vm.postdata.name = "快速审批插件-" + $filter('date')(new Date, "yyyyMMddHHmmss") + $filter('date')(new Date, "sss");
        treeService.sync.then(function(){ 
            vm.nodeStr = treeService.selectname();

        });

        vm.openDetail = function(d){
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/taskDetail.html',
                controller: 'JobDetailController',
                controllerAs: 'jobDetail',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    repoData : function () { return d}
                }
            });
        };

        vm.runapproval = function(){
            $http.post('/api/job/task/' + vm.treeid + "/plugin_approval", vm.postdata ).success(function(data){
                if(data.stat) {
                    vm.openDetail(data.data);
                } else {
                    swal({ title: "提交失败!", text: data.info, type:'error' });
                }

            });
        };

}})();
