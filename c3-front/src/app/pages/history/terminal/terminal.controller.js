(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryTerminalController', HistoryTerminalController);

    function HistoryTerminalController($filter, $state, $http, $uibModal, $scope, ngTableParams) {

        var vm = this;
        $scope.searchStatus = "";
        vm.treeid = $state.params.treeid;
        $scope.nowTime = $filter('date')(new Date, "yyyy-MM-dd");
        vm.timeStart = $scope.nowTime;

        $('#time_start').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.timeStart = result;
            $scope.$apply();
        });

        $('#time_end').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.timeEnd= result;
            $scope.$apply();
        });

        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.startuser = data.email;
            });
        };

        vm.Reset = function () {
            vm.startuser = "";
            vm.runnode = "";
            vm.runusr = "";
            vm.runcmd = "";
            vm.timeStart = $scope.nowTime;
            vm.timeEnd = "";
            vm.reload()
        };

        vm.reload = function () {
            vm.loadover = false
            var get_data = {};

            if(vm.startuser){
                get_data.user=vm.startuser
            }
            if(vm.runnode){
                get_data.node=vm.runnode
            }
            if(vm.runusr){
                get_data.usr=vm.runusr
            }
            if(vm.runcmd){
                get_data.cmd=vm.runcmd
            }
            if(vm.timeStart){
                get_data.time_start=vm.timeStart
            }
            if(vm.timeEnd){
                get_data.time_end=vm.timeEnd
            }
                $http({
                    method:'GET',
                    url:'/api/job/cmd/' + vm.treeid + '/log',
                    params:get_data
                }).then(
                    function successCallback(response) {
                        vm.loadover = true
                        if (response.data.stat){
                            vm.data_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                        }else {
                            swal('获取列表失败', response.data.info, 'error');
                        }
                    },
                    function errorCallback(response) {
                        swal('获取列表失败', response.status, 'error');
                    }
                );
        };
        vm.reload();
    }

})();
