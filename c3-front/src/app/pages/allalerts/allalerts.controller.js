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

        vm.tott = function(d){
            vm.loadover = false;
            $http.post("/api/agent/monitor/alert/tott/0", d  ).success(function(data){
                if(data.stat == true)
                {
                   vm.loadover = true;
                   vm.cancel();
                   swal({ title:'提交成功', text: data.info, type:'success' });
                } else {
                   swal({ title:'提交失败', text: data.info, type:'error' });
                }
            });
        };

        vm.openOneTab = function (url) {
            window.open(url, '_blank')
        };

    }
})();
