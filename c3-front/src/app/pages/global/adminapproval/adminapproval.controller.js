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

        vm.oalog = function(id,show){
            $uibModal.open({
                templateUrl: 'app/pages/global/adminapproval/edit/oalog.html',
                controller: 'AdminApprovalOalogController',
                controllerAs: 'adminapprovaloalog',
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

        vm.oaredo = function(id){
            swal({
                title: "重新发起OA工单",
                text: '重新发起',
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: false,
                showLoaderOnConfirm: true
            }, function(){
                $http.post('/api/job/adminapproval/oaredo/'+ id ).success(function(data){
                    if (data.stat){
                        swal("操作成功!", '成功:' + data.data , "success");
                        vm.reload();
                    }else {
                        swal('操作失败', data.info, 'error');
                    }
                });
            });
        };

        vm.notifyredo = function(id){
            swal({
                title: "重新发起审批消息",
                text: '重新发起',
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: false,
                showLoaderOnConfirm: true
            }, function(){
                $http.post('/api/job/adminapproval/notifyredo/'+ id ).success(function(data){
                    if (data.stat){
                        swal("操作成功!", '成功:' + data.data , "success");
                        vm.reload();
                    }else {
                        swal('操作失败', data.info, 'error');
                    }
                });
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
