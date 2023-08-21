(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('UseraddrController', UseraddrController);

    /** @ngInject */
    function UseraddrController( $state, $http, $uibModal, ngTableParams, $injector ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');
        vm.loadover = true

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/connector/useraddr').then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.dataTable = new ngTableParams({count:100}, {counts:[],data:response.data.data.reverse()});
                        vm.loadover = true
                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response ){
                    swal('获取信息失败', response.status, 'error' );
                });
        };

        vm.reload()

        vm.createUseraddr = function () {
            $uibModal.open({
                templateUrl: 'app/pages/global/useraddr/create.html',
                controller: 'UseraddrCreateController',
                controllerAs: 'useraddrcreate',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    infoId: function () { return null},
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reload}
                }
            });
        };

         vm.testsend = function ( user ) {
            $http.post('/api/agent/monitor/config/usertest', { projectid: vm.treeid, 'user': user}).then(
                function successCallback(response) {
                    if (response.data.stat){
                        swal({title: "消息发送已经提交！", text: "确认是否收到消息", type: 'success'});
                    }else {
                        toastr.error( "发送消息失败：" + response.data.info );
                    }
                },
                function errorCallback (response ){
                    toastr.error( "发送消息添加失败：" + response.status );
                }
            );
        };

       vm.deleteUseraddr = function(id) {
          swal({
            title: "删除用户地址簿",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/connector/useraddr/' + id ).success(function(data){
                if(data.stat == true) {
                    swal({ title: "删除成功!", type:'success' });
                    vm.reload();
                } else {
                    swal({ title: "删除失败!", text: data.info, type:'error' });
                }
            });
          });
        }

        // 编辑地址簿信息
        vm.editUseraddr = function (info) {
          $uibModal.open({
            templateUrl: 'app/pages/global/useraddr/create.html',
            controller: 'UseraddrCreateController',
            controllerAs: 'useraddrcreate',
            backdrop: 'static',
            size: 'lg',
            keyboard: false,
            bindToController: true,
            resolve: {
                infoId: function () { return info.id},
                treeid: function () { return vm.treeid},
                reload : function () { return vm.reload}
            }
        });
        }

    }

})();
