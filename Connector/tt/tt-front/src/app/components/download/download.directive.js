(function(){
    'use strict';

    angular
        .module('cmdb')
        .directive('c3download', c3download);

    /** @ngInject */
    function c3download() {

        var directive = {

            link: linkFunc,
            restrict: 'E',
            templateUrl: 'app/components/download/download.html',
            scope: {
                data: '='
            }
        };

        return directive;

        /** @ngInject */
        function linkFunc(scope) {
            scope.submit = function(){
                var ids = [];
                angular.forEach(scope.data, function(v){
                    ids.push(v.no);
                });
                scope.ids = ids.toLocaleString();
            };
        }

    }

})();
