(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('QuickApprovalController', QuickApprovalController);

    function QuickApprovalController($scope, $state, $http, $injector, ngTableParams, genericService ) {
        var vm = this;
        var toastr = toastr || $injector.get('toastr');
        var uuid = $state.params.uuid;

        vm.seftime = genericService.seftime
        vm.show = false
        vm.stat = {}
        vm.reload = function () {
            $http.get('/api/job/approval/control/' + uuid).then(
                function successCallback(response){
                    if (response.data.stat){
                        vm.dataTable = new ngTableParams({count:25}, {counts:[],data:response.data.data});
                        vm.data = response.data.data[0]
                    }else{
                        toastr.error("获取信息失败:"+response.data.info)
                    }

                },
                function errorCallback (response){
                    toastr.error("获取信息失败:"+response.status)

                });

            $http.get('/api/job/approval/control/status/' + uuid).then(
                function successCallback(response){
                    if (response.data.stat){
                        vm.stat = response.data.data
                    }else{
                        toastr.error("获取信息失败:"+response.data.info)
                    }

                },
                function errorCallback (response){
                    toastr.error("获取信息失败:"+response.status)

                });
 
        };

        vm.edit = function (opinion) {
            $http.post( '/api/job/approval/control', { uuid: uuid, opinion: opinion} ).success(function(data){
                if (data.stat){
                    vm.reload();
                }else {
                    swal({ title: '操作失败', text: data.info, type:'error' });
                }
            });
        };

        vm.reload();

    }
})();
