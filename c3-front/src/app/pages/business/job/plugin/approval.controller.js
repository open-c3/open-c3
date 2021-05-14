(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('approvalJobController', approvalJobController);

    function approvalJobController($state, $http,$uibModalInstance, editData, seq) {

        var vm = this;

        vm.treeid = $state.params.treeid;
        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.postdata = { timeout: '86400', approver: '', cont: '', name: '', deployenv: 'always',action: 'always', batches: 'always', everyone: 'on', plugin_type: 'approval' };
        if (!editData){vm.postdata.name = "审批_"+seq};

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
