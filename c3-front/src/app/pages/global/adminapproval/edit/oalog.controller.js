(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AdminApprovalOalogController', AdminApprovalOalogController);

    function AdminApprovalOalogController($uibModalInstance, $http, id, genericService, $injector,ngTableParams,homereload,show) {

        var vm = this;
        vm.show = show
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.seftime = genericService.seftime
        vm.loadover = false;
        vm.data = {}
        var toastr = toastr || $injector.get('toastr');
        vm.reload = function () {
            $http.get('/api/job/adminapproval/oalog/' + id).then(
                function successCallback(response){
                    if (response.data.stat){
                        vm.data = response.data.data
                        vm.loadover = true
                    }else{
                        toastr.error("获取信息失败:"+response.data.info)
                    }

                },
                function errorCallback (response){
                    toastr.error("获取信息失败:"+response.status)

                });
        };

        vm.reload();

}})();
