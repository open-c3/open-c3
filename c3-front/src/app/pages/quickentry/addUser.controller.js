(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('AddUserController', AddUserController);

    function AddUserController($uibModalInstance, $scope, resoureceService, treeId, reloadUser) {

        var vm = this;

        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.add = function(){
            var d = {
                'username': $scope.username
            };
            resoureceService.user.addUser(treeId,  d, null)
                .then(function () {
                    vm.cancel();
                    reloadUser();
                })
                .finally(function(){

            });
        };
    }
})();

