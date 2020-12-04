(function() {
    'use strict';

    angular
        .module('openc3')
        .directive('cmscript', cmscript);

    /** @ngInject */
    function cmscript() {
        var directive = {

            restrict: 'E',
            templateUrl: 'app/components/scripts/createButton.html',
            scope: {},
            controller: CreateS,
            controllerAs: 'creat'
        };

        return directive;

        /** @ngInject */
        function CreateS($rootScope, treeService, $uibModal) {

            var vm = this;


            vm.creats = function(){
                $uibModal.open({
                    templateUrl: 'app/components/scripts/createScript.html',
                    controller: 'CreateScript',
                    controllerAs: 'c',
                    backdrop: 'static',
                    size: 'lg',
                    keyboard: false,
                    bindToController: true,
                    resolve: {
                        dst: function () { return vm.tree }
                    }
                });
            }

        }
    }

})();
