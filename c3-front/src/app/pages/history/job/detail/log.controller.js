(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryJobDetailLogController', HistoryJobDetailLogController);

    function HistoryJobDetailLogController($uibModalInstance,taskuuid,slave) {
        var vm = this;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.taskuuid = taskuuid;
        vm.logaddr = slave;

}})();
