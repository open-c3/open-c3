(function() {
    'use strict';

    angular
        .module('cmdb')
        .directive('contenteditable', contenteditable);

    /** @ngInject */
    function contenteditable() {

        var directive = {
            restrict: 'A',
            require:'?ngModel',
            link:function(scope, element, attrs, ngModel){
                if (!ngModel) return;

                ngModel.$render = function () {
                    element.html(ngModel.$viewValue || '');
                };

                element.on('blur keyup change', function () {
                    scope.$apply(readViewText);
                });

                function readViewText() {
                    var html = element.html();
                    if (attrs.stripBr && html == '<br>') {
                        html = '';
                    }
                    ngModel.$setViewValue(html);
                }

            }
        };

        return directive;

    }

})();
