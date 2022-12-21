(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AllalertsController', AllalertsController);

    function AllalertsController($http, ngTableParams, $uibModal, genericService) {
        var vm = this;
        vm.seftime = genericService.seftime

        vm.siteaddr = window.location.protocol + '//' + window.location.host;
        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/agent/monitor/alert/0?siteaddr=' + vm.siteaddr).success(function(data){
                if (data.stat){
                    vm.dataTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

        vm.openOneTab = function (ackuuid) {
            var terminalAddr = window.location.protocol + "//" + window.location.host+"/#/ack/" + ackuuid;
            window.open(terminalAddr, '_blank')
        };

    }
})();
