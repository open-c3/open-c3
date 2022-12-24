(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ThirdpartyController', ThirdpartyController);

    function ThirdpartyController($http, ngTableParams, $uibModal, genericService) {
        var vm = this;
        vm.seftime = genericService.seftime

        vm.siteaddr = window.location.protocol + '//' + window.location.host;

        vm.loadover = true;
        vm.openTab = function (app, page) {
            vm.loadover = false;
            $http.get('/api/agent/thirdparty/gotopage/' + app + '/' + page ).success(function(data){
                vm.loadover = true;
                if (data.stat){
                    window.open(data.data, '_blank')
                }else {
                    swal({ title:'获取应用地址失败', text: data.info, type:'error' });
                }
            });
        };

    }
})();
