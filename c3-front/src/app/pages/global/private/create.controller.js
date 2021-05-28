(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('PrivateCreateController', PrivateCreateController);

    function PrivateCreateController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, $injector, treeid, reload ) {

        var vm = this;

        var toastr = toastr || $injector.get('toastr');

        vm.postdata = {};

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
            $http.post('/api/connector/private', vm.postdata ).success(function(data){
                    if(data.stat == true) {
                        vm.cancel();
                        reload();
                    } else { swal({ title: "添加失败!", text: data.info, type:'error' }); }

            });
        };

    }
})();

