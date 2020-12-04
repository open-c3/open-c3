(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('AddToFavoritesController', AddToFavoritesController);

    function AddToFavoritesController($http, $uibModalInstance, $scope, resoureceService, treeid, reload, sourceid, sourcename, $injector ) {

        var vm = this;
        $scope.projectname = sourcename
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.add = function(){
            $http.post('/api/ci/favorites/' + treeid , { name: $scope.projectname, ciid: sourceid } ).success(function(data){
                vm.install = { username: 'root' };
                    if(data.stat == true) {
                        vm.cancel();
                        reload();
                        toastr.success( "收藏成功" )
                    }
                    else
                    {
                        toastr.error( "收藏失败:" + data.info )
                    }
            });
        };
    }
})();

