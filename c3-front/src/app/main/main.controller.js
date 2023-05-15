(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MainController', MainController);

    /** @ngInject */
    function MainController($rootScope, $uibModal, $state) {
        $rootScope.back = function() {
            $window.history.back();
        };
        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.modalIsOpen = false
        vm.isShowSearch = true
        var modalInstance

        vm.handleClick = function () {
          modalInstance = $uibModal.open({
            templateUrl: 'app/components/globalsearch/globalsearch.html',
            controller: 'GlobalSearchPageController',
            controllerAs: 'globalsearch',
            backdrop: 'static',
            size: 'lg',
            keyboard: false,
            bindToController: true,
            resolve: {
              treeid: function () { return vm.treeid },
            }
          });
          vm.modalIsOpen = true
          modalInstance.result.then(function(result) {
            console.log('Modal closed with result:', result);
          },function (reason) {
            vm.modalIsOpen = false
          });
        }

        vm.handleModalIsOpen = function () {
          vm.modalIsOpen = modalInstance && modalInstance.closed !== true;
        }
    }

})();
