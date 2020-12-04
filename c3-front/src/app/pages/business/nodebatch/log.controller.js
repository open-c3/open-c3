(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('OperationLogController', OperationLogController);

    function OperationLogController($uibModalInstance, $state, $http, ngTableParams, $injector) {

        var vm = this;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.reload = function () {
            $http({
                method:'GET',
                url:'/api/jobx/log/' + vm.treeid,
                // params:{"create_time":'2018-04-22'}
            }).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.log_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});

                    }else {
                        toastr.error("获取jobx操作日志失败:" + response.data.info)
                    }
                },
                function errorCallback(response) {
                    toastr.error("获取jobx操作日志失败:" + response.status)
                }
            );
        };
        vm.reload()


    }

})();
