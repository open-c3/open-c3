(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonitortreeunbindController', MonitortreeunbindController);

    /** @ngInject */
    function MonitortreeunbindController( $state, $http, $scope, $uibModal, ngTableParams ) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        vm.checkoldstatus=false;
        vm.checknewstatus=false;
        vm.reloadcheck = function(){
            $http.get('/api/agent/monitor/config/treeunbind/' + vm.treeid ).success(function(data){
                vm.checkstatusloadover = true;
                vm.checkstatusdata = data.data;
                if(  data.data.status )
                {
                    vm.checkoldstatus=true;
                    vm.checknewstatus=true;
                }
                else
                {
                    vm.checkoldstatus=false;
                    vm.checknewstatus=false;
                }
            });
        };

        vm.reloadcheck();

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/agent/monitor/config/treeunbind').then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.dataTable = new ngTableParams({count:100}, {counts:[],data:response.data.data});
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

        vm.savecheckstatus = function(){
          swal({
            title: "保存新状态",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            vm.checkstatus = '0';
            if( vm.checknewstatus == true)
            {
                vm.checkstatus = '1';
            }
            $http.post('/api/agent/monitor/config/treeunbind/' + vm.treeid, { status: vm.checkstatus} ).success(function(data){
                if(data.stat == true)
                {
                    swal({ title: "修改成功!", type:'success' });
                    vm.checkoldstatus= vm.checknewstatus;
                } else {
                    swal({ title: "修改失败!", text: data.info, type:'error' });
                }
            })

          })
        }

        vm.deleteMonitortreeunbind = function(treeid) {
          swal({
            title: "删除解绑",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.post('/api/agent/monitor/config/treeunbind/' + treeid, { 'status': '0' } ).success(function(data){
                if(data.stat == true) {
                    swal({ title: "删除成功!", type:'success' });
                    vm.reload();
                } else {
                    swal({ title: "删除失败!", text: data.info, type:'error' });
                }
            });
          });
        }

    }

})();
