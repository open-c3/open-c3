(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('HistoryJobDetailConfirmController', HistoryJobDetailConfirmController);

    function HistoryJobDetailConfirmController($uibModalInstance, $scope,treeId, msg, postdata, $injector, $http ) {

        var vm = this;
        vm.runmsg = msg;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        var toastr = toastr || $injector.get('toastr');
        vm.Confirm = function(){
            $http.put( '/api/job/subtask/' + treeId, postdata ).success(function(data){
                if (data.stat){
                    vm.cancel();
                }else {
                    toastr.error("操作失败"+data.info);
                }
            });
 
        };
    }
})();

