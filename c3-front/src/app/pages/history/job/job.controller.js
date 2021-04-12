(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryJobController', HistoryJobController);
    function HistoryJobController($filter, $timeout, $state, $http, $scope, ngTableParams, genericService) {

        var vm = this;

        vm.seftime = genericService.seftime

        vm.statuszh = { "": "等待执行", "success": "执行成功", "fail": "执行失败", "refuse": "审批拒绝", "decision": "执行失败", "running": "执行中", "ignore": "忽略", "waiting": "等待中" }

        var nowTime = $filter('date')(new Date, "yyyy-MM-dd");
        vm.starttime = nowTime;
        vm.treeid = $state.params.treeid;
        $scope.searchStatus = "";

        $('#starttime').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.starttime = result;
            $scope.$apply();
        });

        $('#finishtime').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.finishtime= result;
            $scope.$apply();
        });

        vm.taskDetail = function(taskuuid){
            $state.go('home.history.jobdetail', {treeid:vm.treeid,taskuuid:taskuuid});
        };
        vm.quickTaskDetail = function(jobuuid, taskuuid,type){
            $state.go('home.history.jobdetail', {treeid:vm.treeid,taskuuid:taskuuid,jobuuid:jobuuid, jobtype:type});
        };
        vm.redo = function(uuid) {
            swal({
                title: "重做任务",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.post('/api/job/task/' + vm.treeid + "/redo", {"taskuuid":uuid} ).success(function(data){
                    if (data.stat){
                       swal({ title: '成功', type:'success' });
                       var reRun = $timeout(function () { vm.reload(); }, 2000);
                    }else {
                        swal({ title: '失败', text: data.info, type:'error' });
                    }
                });
            });
        };

        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.startuser = data.email;
            });
        };

        vm.Reset = function () {
            vm.taskname = "";
            vm.startuser = "";
            vm.starttime = nowTime;
            vm.finishtime = "";
            vm.searchStatus = "";
            vm.taskuuid = "";
            vm.reload()
        };

        vm.ciinfo = {}
        vm.reload = function () {
            var get_data = {};
            if (vm.taskname){
                get_data.name=vm.taskname
            }
            if(vm.startuser){
                get_data.user=vm.startuser
            }
            if(vm.starttime){
                get_data.time_start=vm.starttime
            }
            if(vm.finishtime){
                get_data.time_end=vm.finishtime
            }
            if(vm.searchStatus){
                get_data.status=vm.searchStatus
            }
            if(vm.taskuuid){
                get_data.taskuuid=vm.taskuuid
            }
            vm.loadover = false;
            if (Object.keys(get_data).length != 0){
                $http({
                    method:'GET',
                    url:'/api/job/task/' + vm.treeid,
                    params:get_data
                }).then(
                    function successCallback(response) {
                        vm.loadover = true;
                        if (response.data.stat){
                            vm.data_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                        }else {
                            swal('获取列表失败', response.data.info, 'error');
                        }
                    },
                    function errorCallback(response) {
                        swal('获取列表失败', response.status, 'error');
                    }
                );}

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

        vm.reload();
    }
})();
