(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('CreateImagesController', CreateImagesController);

    function CreateImagesController($uibModalInstance, $state, $http, $scope, homereload, imagesid, title ) {

        var vm = this;
        vm.title = title
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.postData = { share: 'false' };

        if( imagesid )
        {
            $http.get('/api/ci/images/' + imagesid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.postData = response.data.data
                    }else {
                        swal({ title:'获取镜像详情失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response){
                    swal({ title:'获取镜像详情失败', text: response.status, type:'error' });
                });
        }

        vm.saveImages = function(){
            var uri = '/api/ci/images';
            if( imagesid )
            {
                uri = '/api/ci/images/' + imagesid;
            }
            $http.post(uri, vm.postData ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        homereload();
                        vm.cancel();
                    }else {
                        swal({ title:'保存镜像失败', text: response.data.info, type:'error' });
                    }
                }
            );
        };
    }
})();
