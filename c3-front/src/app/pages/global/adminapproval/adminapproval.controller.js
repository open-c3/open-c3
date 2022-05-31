(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AdminApprovalController', AdminApprovalController);

    function AdminApprovalController($http, ngTableParams, $uibModal, genericService) {
        var vm = this;
        vm.seftime = genericService.seftime
        vm.edit = function(id,show){
            $uibModal.open({
                templateUrl: 'app/pages/global/adminapproval/edit/edit.html',
                controller: 'AdminApprovalEditController',
                controllerAs: 'adminapprovaledit',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    id : function () { return id},
                    show : function () { return show},
                    homereload : function () { return vm.reload},
                }
            });
        };

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/job/adminapproval').success(function(data){
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
