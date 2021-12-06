(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('ConfigEditRelyController', ConfigEditRelyController);

    function ConfigEditRelyController($uibModalInstance, $http, $state, nodeStr, ngTableParams, projectid, $injector ) {

        var vm = this;
        vm.nodeStr = nodeStr;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };
        var toastr = toastr || $injector.get('toastr');

        vm.treeid = $state.params.treeid;

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/ci/rely/' + projectid ).success(function(data){
                vm.relyTable = new ngTableParams({count:20}, {counts:[],data:data.data});
                vm.loadover = true;
            });
        };

        vm.reload();

        vm.reloadticket = function(){
            $http.get('/api/ci/ticket').success(function(data){
                if(data.stat){
                    vm.ticketinfo = data.data;
                }
                else{
                    toastr.error( "获取凭据失败:" + data.info )
                }
            });
        };

        vm.reloadticket();

        vm.addrtype = '';
        vm.changeaddr = function()
        {
            if ( vm.newrely.addr == "" )
            {
                vm.addrtype = ''
            }
            else
            {
                if( vm.newrely.addr.match( /git@/ ) ||  vm.newrely.addr.match( /\.git/ ) )
                {
                    vm.addrtype = 'git';
                }else
                {

                    vm.addrtype = 'svn';
                }
            }
        }

 
        vm.module = { username: '__default__' };
        vm.setUsername = function(name) {
            vm.module.username = name;
        }

        vm.add =function() {
          swal({
            title: "添加依赖",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
             $http.post('/api/ci/rely/' + projectid, vm.newrely ).success(function(data){
                 if(data.stat == true) 
                 { 
                     vm.newrely = {};
                     vm.reload();
                 } else { 
                     toastr.error( "添加失败:" + data.info )
                 }
             });
          });
        }

        vm.del =function(id) {
          swal({
            title: "删除依赖",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
             $http.delete('/api/ci/rely/' + projectid + '/' + id ).success(function(data){
                 if(data.stat == true) 
                 { 
                     toastr.success( "删除成功!" )
                     vm.reload();
                 } else { 
                     toastr.error( "删除失败:" + data.info )
                 }
             });
          });
        }
    }
})();
