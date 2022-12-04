(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AllackController', AllackController);

    function AllackController($http, ngTableParams, $uibModal, genericService) {
        var vm = this;
        vm.seftime = genericService.seftime

        vm.edit = function (ackuuid,type,mt) {
            $http.post( '/api/agent/monitor/ack/allack/bycookie', { uuid: ackuuid,type: type, mt: mt} ).success(function(data){
                if (data.stat){
                    vm.reload();
                }else {
                    swal({ title: '操作失败', text: data.info, type:'error' });
                }
            });
        };

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/agent/monitor/ack/allack/bycookie').success(function(data){
                if (data.stat){
                    vm.dataTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();
    }
})();
