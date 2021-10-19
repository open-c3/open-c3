(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateMonitorConfigController', CreateMonitorConfigController);

    function CreateMonitorConfigController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, postData, title) {

        var vm = this;
        vm.title = title
        vm.postData = { 'type': 'port', 'subtype': 'tcp' }
        if( postData.id )
        {
            vm.postData.id = postData.id
            vm.postData.type = postData.type
            vm.postData.subtype = postData.subtype
            vm.postData.content1 = postData.content1
            vm.postData.content2 = postData.content2
        }

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.changeType = function(subtype){
            vm.postData.subtype = subtype;
            vm.postData.content1 = "";
            vm.postData.content2 = "";
        }
        vm.add = function(){
            $http.post('/api/agent/monitor/config/collector/' + treeid , vm.postData ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "添加监控指标采集失败!", text: data.info, type:'error' }); }
            });
        };
    }
})();

