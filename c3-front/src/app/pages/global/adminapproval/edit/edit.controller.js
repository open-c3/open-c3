(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AdminApprovalEditController', AdminApprovalEditController);

    function AdminApprovalEditController($uibModalInstance, $http, id, genericService, $injector,ngTableParams,homereload,show) {

        var vm = this;
        vm.show = show
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.seftime = genericService.seftime
        vm.loadover = false;
        vm.data = {}
        var toastr = toastr || $injector.get('toastr');
        vm.reload = function () {
            $http.get('/api/job/adminapproval/' + id).then(
                function successCallback(response){
                    if (response.data.stat){
                        vm.dataTable = new ngTableParams({count:25}, {counts:[],data:response.data.data});
                        vm.data = response.data.data[0]
                        vm.loadover = true
                    }else{
                        toastr.error("获取信息失败:"+response.data.info)
                    }

                },
                function errorCallback (response){
                    toastr.error("获取信息失败:"+response.status)

                });
        };

        vm.edit = function (opinion) {
            $http.post( '/api/job/adminapproval', { id: id, opinion: opinion} ).success(function(data){
                if (data.stat){
                    homereload();
                    vm.cancel()
                }else {
                    swal({ title: '操作失败', text: data.info, type:'error' });
                }
            });
        };

        vm.reload();

}})();
