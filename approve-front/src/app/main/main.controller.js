(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MainController', MainController);

    /** @ngInject */
    function MainController($rootScope) {
        $rootScope.back = function() {
            $window.history.back();
        };

    }

})();
