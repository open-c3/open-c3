(function(){
    'use strict';

    angular
        .module('openc3')
        .directive('cmfooter', cmfooter);

    function cmfooter() {

        var directive = {

            restrict: 'E',
            templateUrl: 'app/components/footer/footer.html',
            scope: {},
            controller: footerController,
            controllerAs: 'footer'
        };

        return directive;

        function footerController() {

            var vm = this;

            vm.year = (new Date()).getFullYear();

        }

    }

})();
