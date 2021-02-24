(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('CreateImagesController', CreateImagesController);

    function CreateImagesController($uibModalInstance, $state, $http, $scope, homereload, imagesid, title, $injector ) {

        var vm = this;
        vm.title = title
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.postData = { share: 'false' };
        vm.uploadstatus = 0;
        vm.imagesid = imagesid

        var toastr = toastr || $injector.get('toastr');



        vm.bytesToSize = function(bytes) {
            if (bytes === 0) return '0 B';
            var k = 1000, // or 1024
                sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
                i = Math.floor(Math.log(bytes) / Math.log(k));
 
           return (bytes / Math.pow(k, i)).toPrecision(3) + ' ' + sizes[i];
        }


        vm.loadimagesinfo = function( imagesid )
        {
            $http.get('/api/ci/images/' + imagesid + '/upload' ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.uploadstatus = response.data.data
                    }else {
                        swal({ title:'检测镜像失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response){
                    swal({ title:'检查镜像失败', text: response.status, type:'error' });
                });

        }
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

                vm.loadimagesinfo( imagesid )
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

        $scope.upForm = function () {
            var form = new FormData();
            var file = document.getElementById("choicefilesx").files[0];
            form.append('file', file);
            $http({
                method: 'POST',
                url: '/api/ci/images/' + imagesid + '/upload',
                data: form,
                headers: {'Content-Type': undefined},
                transformRequest: angular.identity
            }).success(function (data) {
                if (data.stat){
                    vm.loadimagesinfo( imagesid )
                }
                else
                {
                    toastr.error("上传失败:" + data.info)
                }
            }).error(function (data) {
                toastr.error("上传失败:" + data)
            })
        };

        vm.clickImport = function () {
            document.getElementById("choicefilesx").click();
        };
    }
})();
