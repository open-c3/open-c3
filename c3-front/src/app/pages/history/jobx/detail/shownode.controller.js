(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('showNodeController', showNodeController);

    function showNodeController($uibModalInstance, $state, nodes) {

        var vm = this;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.nodes = nodes;

}})();
