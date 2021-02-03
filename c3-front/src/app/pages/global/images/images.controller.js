(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ImagesController', ImagesController);

    function ImagesController($state, $http, $uibModal, $scope, ngTableParams) {

        var vm = this;
        vm.createImages = function () {
            $uibModal.open({
                templateUrl: 'app/pages/global/images/createImages.html',
                controller: 'CreateImagesController',
                controllerAs: 'createimages',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    imagesid: function () {},
                    homereload: function () { return vm.reload },
                    title: function () { return '新建镜像' },
                }
            });

        };

        vm.deleteImages = function(id){
          swal({
            title: "删除镜像",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){

            $http.delete( '/api/ci/images/' + id ).success(function(data){
                if (data.stat){
                    vm.reload();
                }else {
                    swal({ title:'删除镜像列表失败', text: data.info, type:'error' });
                }
            });

          });
        };

        vm.editImages = function(id){
            $uibModal.open({
                templateUrl: 'app/pages/global/images/createImages.html',
                controller: 'CreateImagesController',
                controllerAs: 'createimages',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    imagesid: function () { return id},
                    homereload: function () { return vm.reload },
                    title: function () { return '编辑镜像' },
                }
            });
        };

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/ci/images').success(function(data){
                if (data.stat){
                    vm.group_Table = new ngTableParams({count:25}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                }else {
                    swal({ title:'获取镜像列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();

    }

})();
