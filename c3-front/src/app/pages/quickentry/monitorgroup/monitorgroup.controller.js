(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonitorGroupController', MonitorGroupController);

    function MonitorGroupController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, genericService, $scope, $injector, $sce ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();

        });

        vm.siteaddr = window.location.protocol + '//' + window.location.host;

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/monitor/config/group' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.groupTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载监控组列表失败:" + data.info )
                }
            });
        };

        vm.reload();

        vm.createGroup = function (postData, title) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitorgroup/create/group.html',
                controller: 'CreateMonitorGroupGroupController',
                controllerAs: 'createMonitorGroupGroup',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reload},
                    title: function(){ return title},
                    postData: function(){ return postData}
                }
            });
        };

        vm.editGroupUser = function (groupid) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitorgroup/create/user.html',
                controller: 'CreateMonitorGroupUserController',
                controllerAs: 'createMonitorGroupUser',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reload},
                    groupid: function(){ return groupid }
                }
            });
        };

        vm.deleteGroup = function(id) {
          swal({
            title: "是否要删除该报警组",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/monitor/config/group/' + id ).success(function(data){
                if( ! data.stat ){ toastr.error("删除报警组:" + date.info)}
                vm.reload();
            });
          });
        }
    }
})();
