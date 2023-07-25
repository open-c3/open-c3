(function(){
    'use strict';

    angular
        .module('openc3')
        .directive('cmloading', loading);

    function loading() {
        var directive = {
            restrict: 'E',
            templateUrl: 'app/components/loading/loading.html',
            scope: {
              isCoverage: '=' // 添加 isCoverage 属性到指令的作用域中
            }
        };
        return directive;
    }

})();
