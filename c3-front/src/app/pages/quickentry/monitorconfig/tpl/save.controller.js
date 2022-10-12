(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('TplSaveMonitorConfigRuleController', TplSaveMonitorConfigRuleController);

    function TplSaveMonitorConfigRuleController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.name = '';
        vm.add = function(){
            $http.post('/api/agent/monitor/config/ruletpl/save/' + treeid  + '/' + vm.name ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                } else { swal({ title: "保存模板失败!", text: data.info, type:'error' }); }
            });
        };

    }
})();

