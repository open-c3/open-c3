(function(){
    'use strict';

    angular
        .module('cmdb')
        .directive('cmloading', loading);

    /** @ngInject */
    function loading() {
        var directive = {
            restrict: 'E',
            templateUrl: 'app/components/loading/loading.html'
        };
        return directive;
    }

})();
