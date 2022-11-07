(function(){
    'use strict';

    angular
        .module('cmdb')
        .directive('c3footer', c3footer);

    /** @ngInject */
    function c3footer() {

        var directive = {

            //link: linkFunc,
            restrict: 'E',
            templateUrl: 'app/components/footer/footer.html',
            scope: {},
            controller: footerController,
            controllerAs: 'footer'
        };

        return directive;

        /** @ngInject */
        function footerController() {

            var vm = this;

            vm.year = (new Date()).getFullYear();

        }

    }

})();
