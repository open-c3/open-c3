(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateProjectController', CreateProjectController);

    function CreateProjectController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload) {

        var vm = this;

        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.add = function(){
            $http.post('/api/ci/group/' + treeid , { name: $scope.projectname } ).success(function(data){
                vm.install = { username: 'root' };
                    if(data.stat == true) {
                        vm.cancel();
                        reload();
                    } else { swal({ title: "创建失败!", text: data.info, type:'error' }); }

            });
        };
    }
})();

