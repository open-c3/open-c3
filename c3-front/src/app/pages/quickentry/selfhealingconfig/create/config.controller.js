(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateSelfHealingConfigController', CreateSelfHealingConfigController);

    function CreateSelfHealingConfigController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, postData, title) {

        var vm = this;
        vm.title = title
        vm.postData = { }
        if( postData.id )
        {
            vm.postData.id = postData.id
            vm.postData.name = postData.name
            vm.postData.altername = postData.altername
            vm.postData.jobname = postData.jobname
        }

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
            $http.post('/api/agent/selfhealing/config', vm.postData ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "添加自愈套餐失败!", text: data.info, type:'error' }); }
            });
        };
    }
})();

