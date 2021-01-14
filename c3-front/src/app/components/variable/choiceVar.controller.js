(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('ChoiceVarController', ChoiceVarController);

    function ChoiceVarController($uibModalInstance,$timeout,$state, $http, $scope) {

        var vm = this;
        var ss = window.location.href;
        if(ss.split("#")[1].indexOf("/distribute/") !=-1){
            $scope.ciData = {
                'ci':"",
                'version':""
            };
        }else {
            $scope.ciData = {
                'ci':"default",
                'version':"$version"
            };
        }


        vm.treeid = $state.params.treeid;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.chioceover = function(){
            $uibModalInstance.close(
                $scope.ciData
            );
        };



    }
})();

