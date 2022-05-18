(function() {
    'use strict';

    angular
        .module('openc3')
        .directive('dataerror', errController);

    function errController() {
        var directive = {

            restrict: 'E',
            templateUrl: 'app/components/error/errorMsg.html',
            scope: {errmsg: "@"},
            controller: ErrorMsg,
            controllerAs: 'errormsg'
        };
        return directive;
        function ErrorMsg() {
            var vm = this;
        }



    }

})();