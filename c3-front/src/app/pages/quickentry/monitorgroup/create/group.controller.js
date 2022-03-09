(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateMonitorGroupGroupController', CreateMonitorGroupGroupController);

    function CreateMonitorGroupGroupController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, postData, title) {

        var vm = this;
        vm.title = title
        vm.postData = {}
        if( postData.id )
        {
            vm.postData.id = postData.id
            vm.postData.name = postData.name
            vm.postData.description = postData.description
        }

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
            $http.post('/api/agent/monitor/config/group', vm.postData ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }
            });
        };
    }
})();

