(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('approvalJobController', approvalJobController);

    function approvalJobController($state, $http,$uibModalInstance, editData, jobName) {

        var vm = this;

        vm.treeid = $state.params.treeid;
        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.postdata = { timeout: '86400', approver: '', cont: '', name: '', deployenv: 'always',action: 'always', batches: 'always', everyone: 'on', plugin_type: 'approval' };
        if (jobName){vm.postdata.name = jobName+"_审批"};

        if( editData )
        {
            vm.postdata = editData
        }

        vm.returnData = function () {
            var post_data = vm.postdata;
            $uibModalInstance.close(
                post_data
            );
            vm.cancel()
        };

}})();
