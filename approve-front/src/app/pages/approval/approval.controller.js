(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ApprovalController', ApprovalController);

    function ApprovalController($http, ngTableParams, $uibModal, genericService) {
        var vm = this;
        vm.seftime = genericService.seftime
        vm.edit = function(uuid,show){
            $uibModal.open({
                templateUrl: 'app/pages/approval/edit/edit.html',
                controller: 'ApprovalEditController',
                controllerAs: 'approvaledit',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    uuid : function () { return uuid},
                    show : function () { return show},
                    homereload : function () { return vm.reload},
                }
            });
        };

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/job/approve/approval').success(function(data){
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
