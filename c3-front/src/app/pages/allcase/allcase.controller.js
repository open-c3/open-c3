(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AllcaseController', AllcaseController);

    function AllcaseController($http, ngTableParams, $uibModal, genericService) {
        var vm = this;
        vm.seftime = genericService.seftime

        vm.reloadC = function () {
            vm.loadover = false;
            $http.get('/api/agent/monitor/caseinfo/allcase').success(function(data){
                if (data.stat){
                    vm.dataTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };

        vm.siteaddr = window.location.protocol + '//' + window.location.host;

        vm.alertsuuid = {};
        vm.reloadA = function () {
            vm.loadAover = false;
            $http.get('/api/agent/monitor/alert/0?siteaddr=' + vm.siteaddr + '&uuidonly=1').success(function(data){
                if (data.stat){
                    vm.alertsuuid = data.data;
                    vm.loadAover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };

        vm.tottbind = {};
        vm.reloadB = function () {
            vm.loadBover = false;
            $http.get('/api/agent/monitor/alert/tottbind/0').success(function(data){
                if (data.stat){
                    vm.tottbind = data.data;
                    vm.loadBover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload = function () {
            vm.reloadA();
            vm.reloadB();
            vm.reloadC();
        };

        vm.reload();

        vm.openTT = function (uuid, caseuuid) {
            vm.loadover = false;
            $http.get('/api/agent/monitor/alert/gotocase/0?uuid=' + uuid + '&caseuuid=' + caseuuid ).success(function(data){
                if (data.stat){
                    vm.loadover = true;
                    window.open(data.data, '_blank')
                }else {
                    swal({ title:'获取工单地址失败', text: data.info, type:'error' });
                }
            });
        };

        vm.openOneTab = function (ackuuid) {
            var terminalAddr = window.location.protocol + "//" + window.location.host+"/#/ack/" + ackuuid;
            window.open(terminalAddr, '_blank')
        };

    }
})();
