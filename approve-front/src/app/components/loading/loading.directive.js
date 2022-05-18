(function(){
    'use strict';

    angular
        .module('openc3')
        .directive('cmloading', loading);

    function loading() {
        var directive = {
            restrict: 'E',
            templateUrl: 'app/components/loading/loading.html'
        };
        return directive;
    }

})();
