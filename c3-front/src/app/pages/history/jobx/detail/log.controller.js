(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryJobxDetailLogController', HistoryJobxDetailLogController);

    function HistoryJobxDetailLogController($uibModalInstance,taskuuid,slave) {
        var vm = this;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.taskuuid = taskuuid;
        vm.logaddr = slave;

}})();
