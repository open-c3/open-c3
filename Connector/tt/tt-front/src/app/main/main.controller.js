(function() {
    'use strict';

    angular
        .module('cmdb')
        .controller('MainController', MainController);

    /** @ngInject */
    function MainController($document, $log, $rootScope, $state, $window) {

        $rootScope.back = function(){
            $state.go('home');
        };

        angular.element('.scroller').css('height', $window.innerHeight-50);
        angular.element($window).bind('resize', function(){
            angular.element('.scroller').css('height', $window.innerHeight-50);
        });

        $rootScope.resizeMenu = function(){
            angular.element('.scroller').css('height', $window.innerHeight-50);
        };
    }

})();
