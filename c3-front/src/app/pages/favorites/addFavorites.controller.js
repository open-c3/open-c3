(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AddFavoritesController', AddFavoritesController);

    function AddFavoritesController( $uibModalInstance, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, homereload, $injector ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); homereload();};

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });


        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/ci/group/all/' + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.activeRegionTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载版本失败:" + data.info );
                }
            });
        };

        vm.reload();

        vm.addToFavorites = function (id, name) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/addToFavorites.html',
                controller: 'AddToFavoritesController',
                controllerAs: 'addToFavorites',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    sourceid: function () { return id},
                    sourcename: function () { return name},
                    reload : function () { return vm.reload}
                }
            });
        };

        vm.delToFavorites = function(id) {
          swal({
            title: "取消收藏",
            text: "取消",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/ci/favorites/' + vm.treeid + '?ciid=' + id ).success(function(data){
                if(data.stat){
                    vm.reload();
                }else{
                    toastr.error( "取消收藏失败:" + data.info )
                }
            });
          });
        }

    }
})();
