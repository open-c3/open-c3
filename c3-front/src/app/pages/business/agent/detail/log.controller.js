(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AgentCtrlLogController', AgentCtrlLogController);

    /** @ngInject */
    function AgentCtrlLogController($uibModalInstance,$location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });


        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/log/' + vm.treeid).success(function(data){
                vm.activeRegionTable = new ngTableParams({count:50}, {counts:[],data:data.data});
                vm.loadover = true;
            });
        };

        vm.reload();

    }
})();
