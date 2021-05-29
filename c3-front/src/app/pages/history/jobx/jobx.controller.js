(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryJobxController', HistoryJobxController)
        .filter('showversion', function () {
            return function (text) {
                var w = '';
                var re=/\bversion:.*/;
                if (re.test(text)){
                    var reStr = re.exec(text)[0];
                    w = reStr.split(":")[1]
                }
             
                return w

            }
        });

    function HistoryJobxController($state, $http, $uibModal, $scope, ngTableParams, $filter, genericService, $injector) {
        var vm = this;
        var nowTime = $filter('date')(new Date, "yyyy-MM-dd");

        vm.seftime = genericService.seftime
        vm.statuszh = { "": "等待执行", "success": "执行成功", "fail": "执行失败", "decision": "执行失败", "running": "执行中", "ignore": "忽略", "waiting": "等待中" }

        var toastr = toastr || $injector.get('toastr');
        $scope.searchData = {
            'name':null,
            'user':null,
            'status':null,
            'time_start': nowTime,
            'time_end':null,
            'taskuuid':null
        };
        vm.treeid = $state.params.treeid;

        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                $scope.searchData.user = data.email;
            });
        };

        $('#createstart').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            $scope.searchData.time_start = result;
            $scope.$apply();
        });

        $('#createend').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            $scope.searchData.time_end= result;
            $scope.$apply();
        });

        vm.Reset = function () {
            angular.forEach($scope.searchData, function (value, key) {
                $scope.searchData[key] = null;
            });
            vm.reload();
        };

        vm.ciinfo = {}
        vm.reload = function () {
            vm.loadover = false
            var get_data = {};
            angular.forEach($scope.searchData, function (value, key) {
                if (value){
                    get_data[key] = value;
                }
            });
            $http({
                method:'GET',
                url:'/api/jobx/task/' + vm.treeid,
                params:get_data
            }).then(
                function successCallback(response) {
                    vm.loadover = true
                    if (response.data.stat){
                        vm.task_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                    }else {
                        swal('获取列表失败', response.data.info, 'error');
                    }
                },
                function errorCallback(response) {
                    swal('获取列表失败', response.status, 'error');
                }
            );

            $http.get('/api/ci/group/' + vm.treeid).success(function(data){
                if(data.stat)
                {
                    angular.forEach(data.data, function (value, key) {
                        vm.ciinfo['_ci_'+value.id+'_'] = value.name
                    });
                }
                else
                {
                    toastr.error( "加载流水线名称失败:" + data.info )
                }
            });
        };

        vm.showRollback = function (info){
            var uuid = info.uuid;
            uuid = uuid.slice(uuid.length - 1);
            if (64 < uuid.charCodeAt(0) && uuid.charCodeAt(0) < 91) {
                return '是'
            } else {
                return ''
            }
        };

        vm.taskDetail = function(uuid){
            $state.go('home.history.jobxdetail', {treeid:vm.treeid, taskuuid:uuid, accesspage:true});

        };

        vm.reload();
    }

})();
