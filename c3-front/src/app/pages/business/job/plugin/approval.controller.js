(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('approvalJobController', approvalJobController);

    function approvalJobController($state, $http,$uibModalInstance, editData, seq) {

        var vm = this;

        vm.treeid = $state.params.treeid;
        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.postdata = { timeout: '86400', approver: '', cont: 'defaultTemplate', name: '', deployenv: 'always',action: 'always', batches: 'always', everyone: 'on', plugin_type: 'approval', relaxed: 'off' };

        vm.content1 = 'defaultTemplate';
        vm.content2 = '发布审批：${stepname}\n\n提交人：${submitter};\n\n流水线名: ${flowname};\n服务树名称: ${treename};\n\n发布版本: ${version};\n${rollback}\n\n发布环境: ${deploy_env}\n\n发现tag的时间: ${tagtime}\n打tag的人: ${tagger}\n发布版本tag信息: ${taginfo}\n';

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
