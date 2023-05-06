(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryTtGotoController', HistoryTtGotoController);

    function HistoryTtGotoController($interval, $location, $state, $http, $uibModal, $stateParams, $scope, $injector, genericService) {

        window.open('/tt/#/tt/show/' + $stateParams.ttuuid, '_self');

    }

})();
