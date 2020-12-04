(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('EmptyVarController', EmptyVarController);

    function EmptyVarController($uibModalInstance,$state, $http, $scope, emptyData) {

        var vm = this;
        vm.emptyVar = emptyData;
        vm.treeid = $state.params.treeid;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.inputOver = function(){
            $uibModalInstance.close(
                vm.emptyVar
            );
        };



    }
})();

