(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonitorNodeLowController', MonitorNodeLowController);

    function MonitorNodeLowController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, genericService, $scope, $injector, $sce ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });


        $scope.count1 = 0;
        $scope.count2 = 0;
        $scope.count3 = 0;
        $scope.count4 = 0;

        vm.openNewWindow = function( ip )
        {
            var url = '/third-party/monitor/grafana/d/rYdddlPWk/node-exporter-full?orgId=1&from=now-14d&to=now&var-DS_PROMETHEUS=default&var-job=openc3&var-node=' + ip + '&var-diskdevices=%5Ba-z%5D%2B%7Cnvme%5B0-9%5D%2Bn%5B0-9%5D%2B%7Cmmcblk%5B0-9%5D%2B';
            window.open( url, '_blank')
        }

        vm.allData = [];

        vm.dataGrep = function( stat ){
            vm.tempdata = [];
            angular.forEach(vm.allData, function (data, index) {
               if( data.status == stat )
               {
                   vm.tempdata.push( data );
               }
           });

           vm.dataTable = new ngTableParams({count:20}, {counts:[],data:vm.tempdata.reverse()});
        }

        vm.reload = function(){
            vm.loadover = false;

            $scope.count1 = 0;
            $scope.count2 = 0;
            $scope.count3 = 0;
            $scope.count4 = 0;

            $http.get('/api/agent/nodelow/' + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.dataTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.allData = data.data;

                    angular.forEach(data.data, function (data, index) {
                        if( data.status == 'low' )
                        {
                            $scope.count1 = $scope.count1 + 1
                        }
                        if( data.status == 'warn' )
                        {
                            $scope.count2 = $scope.count2 + 1
                        }
                        if( data.status == 'normal' )
                        {
                            $scope.count3 = $scope.count3 + 1
                        }
                        if( data.status == 'unkown' )
                        {
                            $scope.count4 = $scope.count4 + 1
                        }
                    });

                    vm.loadover = true;
                } else { 
                    toastr.error( "加载数据失败:" + data.info )
                }
            });
        };

        vm.reload();

        vm.showDetail = function (ip) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitornodelow/detail.html',
                controller: 'MonitorNodeLowDetailController',
                controllerAs: 'MonitorNodeLowDetail',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid },
                    reload: function () { return vm.reload },
                    ip:     function () { return ip }
                }
            });
        };

    }
})();
