(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('TplSyncMonitorConfigRuleController', TplSyncMonitorConfigRuleController);

    function TplSyncMonitorConfigRuleController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.name = '';
        vm.data = [];
        vm.reload = function(){
            $http.get('/api/agent/monitor/config/ruletpl/' + vm.treeid ).success(function(data){
                if(data.stat == true) {
                    vm.data = data.data;
                } else { swal({ title: "获取模板列表失败!", text: data.info, type:'error' }); }
            });
        };

        vm.reload();
        vm.add = function(){
            $http.post('/api/agent/monitor/config/ruletpl/sync/' + treeid  + '/' + vm.name ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "添加失败!", text: data.info, type:'error' }); }
            });
        };

    }
})();

