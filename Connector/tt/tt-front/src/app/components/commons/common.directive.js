(function(){
    'use strict';

    angular
        .module('cmdb')
        .directive('toggleClass', toggleClass);

    /** @ngInject */
    function toggleClass() {
        return {
            restrict: 'A',
            link: function(scope, element, attrs) {
                element.bind('click', function() {
                    element.toggleClass(attrs.toggleClass);
                });
            }
        };
    }

    angular
        .module('cmdb')
        .directive('toggleParentClass', toggleParentClass);

    /** @ngInject */
    function toggleParentClass() {
        return {
            restrict: 'A',
            link: function(scope, element, attrs) {
                element.bind('click', function() {
                    element.parent().toggleClass(attrs.toggleClass);
                });
            }
        };
    }

    angular
        .module('cmdb')
        .directive('toggleHover', toggleHover);

    /** @ngInject */
    function toggleHover() {
        return {
            restrict: 'A',
            link: function(scope, element, attrs) {
                element.bind('hover', function() {
                    element.toggleClass(attrs.toggleClass);
                });
            }
        };
    }

    // detail page use
    // toggle next element, hide others
    angular
        .module('cmdb')
        .directive('toggleNext', toggleNext);

    /** @ngInject */
    function toggleNext() {
        return {
            restrict: 'A',
            link: function(scope, element) {
                element.bind('click', function() {

                    var needHide = false;
                    if(element.next().hasClass('hide')){
                        needHide = false;
                    }else{
                        needHide = true;
                    }

                    if(needHide){
                        element.next().addClass('hide');
                    }else{
                        element.next().removeClass('hide');
                    }

                });
            }
        };
    }

    angular
        .module('cmdb')
        .directive('convertToNumber', convertToNumber);

    /** @ngInject */
    function convertToNumber() {
        return {
            require: 'ngModel',
            link: function(scope, element, attrs, ngModel) {
                ngModel.$parsers.push(function(val) {
                    return parseInt(val, 10);
                });
                ngModel.$formatters.push(function(val) {
                    if (val != undefined){
                        return '' + val;
                    }else{
                        return '';
                    }
                });
            }
        };
    }

})();
