(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateMonitorConfigRuleController', CreateMonitorConfigRuleController);

    function CreateMonitorConfigRuleController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, postData, title) {

        var vm = this;
        vm.title = title
        vm.postData = { 'severity': 'warning' }
        if( postData.id )
        {
            vm.postData.id = postData.id
            vm.postData.alert = postData.alert
            vm.postData.expr = postData.expr
            vm.postData.for = postData.for
            vm.postData.severity = postData.severity
            vm.postData.summary = postData.summary
            vm.postData.description = postData.description
            vm.postData.value = postData.value
        }

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
            $http.post('/api/agent/monitor/config/rule/' + treeid , vm.postData ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "添加监控指标采集失败!", text: data.info, type:'error' }); }
            });
        };
    }
})();

