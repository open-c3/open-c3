(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MainController', MainController);

    /** @ngInject */
    function MainController($rootScope, $uibModal, $state, $location) {
        $rootScope.back = function() {
            $window.history.back();
        };
        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.modalIsOpen = false
        vm.isShowSearch = true
        vm.isNotShow = false
        vm.isClose = false
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
        vm.handleOpen = function () {
          window.open('https://github.com/open-c3/open-c3/issues')
        }

        vm.handleDosc = function () {
          window.open('/book/index.html')
        }

        vm.handleModalIsOpen = function () {
          vm.modalIsOpen = modalInstance && modalInstance.closed !== true;
        }

        vm.handleVisible = function () {
          vm.isNotShow = !vm.isNotShow
        }

        vm.handleClose = function () {
          vm.isClose = true
        }

        // 监听路由变化
        $rootScope.$watch(function() { return $location.path(); }, function(newPath) {
          vm.selectLocation = newPath.includes('/search')
          vm.isShowSearch = !vm.selectLocation
        });
    }

})();
