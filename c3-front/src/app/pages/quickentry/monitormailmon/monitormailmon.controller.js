(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonitorMailmonController', MonitorMailmonController);

    function MonitorMailmonController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, genericService, $scope, $injector, $sce ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();

        });

        vm.siteaddr = window.location.protocol + '//' + window.location.host;

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/monitor/config/mailmon' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.mailmonTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载邮件监控列表失败:" + data.info )
                }
            });
        };

        vm.reload();

        vm.reloadx = function(){
            vm.loadxover = false;
            $http.get('/api/agent/monitor/config/mailmon/history' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.mailmonHistoryTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadxover = true;
                } else { 
                    toastr.error( "加载邮件列表失败:" + data.info )
                }
            });
        };

        vm.reloadx();

        vm.createMailmon = function (postData, title) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitormailmon/create/mailmon.html',
                controller: 'CreateMonitorMailmonMailmonController',
                controllerAs: 'createMonitorMailmonMailmon',
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

        vm.deleteMailmon = function(id) {
          swal({
            title: "是否要删除该邮件监控项",
            text: "删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/monitor/config/mailmon/' + id ).success(function(data){
                if( ! data.stat ){ toastr.error("删除邮件监控项:" + date.info)}
                vm.reload();
            });
          });
        }
    }
})();
