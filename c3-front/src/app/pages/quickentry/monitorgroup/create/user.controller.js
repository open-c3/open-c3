(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateMonitorGroupUserController', CreateMonitorGroupUserController);

    function CreateMonitorGroupUserController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, groupid, $injector ) {

        var vm = this;
        vm.user='';
        vm.cancel = function(){ $uibModalInstance.dismiss()};

        var toastr = toastr || $injector.get('toastr');

        vm.add = function(){
            $http.post('/api/agent/monitor/config/groupuser', { 'groupid': groupid, 'user': vm.user }  ).success(function(data){
                if(data.stat == true) {
                    vm.reload();
                } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }
            });
        };

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/monitor/config/groupuser/' + groupid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.groupuserTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载数据失败:" + data.info )
                }
            });
        };

        vm.reload();

        vm.deleteUser = function(id) {
          swal({
            title: "是否要删除该用户",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/monitor/config/groupuser/' + id ).success(function(data){
                if( ! data.stat ){ toastr.error("删除失败:" + data.info)}
                vm.reload();
            });
          });
        }
    }
})();

