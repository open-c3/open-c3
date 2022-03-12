(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonitorOncallController', MonitorOncallController);

    function MonitorOncallController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, genericService, $scope, $injector, $sce ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();

        });

        vm.siteaddr = window.location.protocol + '//' + window.location.host;

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/monitor/config/oncall' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.oncallTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载监控组列表失败:" + data.info )
                }
            });
        };

        vm.reload();

        vm.createOncall = function (postData, title) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitoroncall/create/oncall.html',
                controller: 'CreateMonitorOncallOncallController',
                controllerAs: 'createMonitorOncallOncall',
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

        vm.oncallCal = function (postData) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitoroncall/create/cal.html',
                controller: 'CreateMonitorOncallCalController',
                controllerAs: 'createMonitorOncallCal',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reload},
                    postData: function(){ return postData}
                }
            });
        };

        vm.oncallList = function (postData) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitoroncall/create/list.html',
                controller: 'CreateMonitorOncallListController',
                controllerAs: 'createMonitorOncallList',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    reload : function () { return vm.reload},
                    postData: function(){ return postData}
                }
            });
        };

        vm.deleteOncall = function(id) {
          swal({
            title: "是否要删除该值班组",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/monitor/config/oncall/' + id ).success(function(data){
                if( ! data.stat ){ toastr.error("删除值班组:" + date.info)}
                vm.reload();
            });
          });
        }
    }
})();
