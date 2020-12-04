(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CiAddImageController', CiAddImageController);

    function CiAddImageController($uibModalInstance, $http) {
        var vm = this;
        vm.cancel_show = function(){ $uibModalInstance.dismiss(); };
 
     }
})();
