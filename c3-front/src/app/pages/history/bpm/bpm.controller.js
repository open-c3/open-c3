(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryBpmController', HistoryBpmController);
    function HistoryBpmController($filter, $timeout, $state, $http, $scope, ngTableParams, genericService ) {

        var vm = this;

        vm.seftime = genericService.seftime
        vm.exportDownload = genericService.exportDownload
        vm.myflow = $state.params.type.indexOf('myflow')
        vm.mytask = $state.params.type.indexOf('mytask')
        vm.mylink = $state.params.type.indexOf('mylink')

        vm.statuszh = { "": "等待执行", "success": "执行成功", "fail": "执行失败", "refuse": "审批拒绝", "decision": "执行失败", "running": "执行中", "ignore": "忽略", "waiting": "等待中" }

        vm.tableData = [];
        var today = new Date();
        var thirtyDaysAgo = new Date(today.getTime() - (30 * 24 * 60 * 60 * 1000));
        var nowTime = $filter('date')(thirtyDaysAgo, "yyyy-MM-dd");
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

        vm.editBpmForm = function(uuid){
            window.open('/#/bpm/0/' + uuid, '_blank')
        };

        vm.taskDetail = function(taskuuid){
            $state.go('home.history.bpmdetail', {treeid: '0',taskuuid:taskuuid});
        };
        vm.quickTaskDetail = function(jobuuid, taskuuid,type){
            $state.go('home.history.jobdetail', {treeid: '0',taskuuid:taskuuid,jobuuid:jobuuid, jobtype:type});
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
                $http.post('/api/job/task/' + '0' + "/redo", {"taskuuid":uuid} ).success(function(data){
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

        vm.reload = function () {
            var get_data = {};
            if (vm.taskname){
                get_data.alias=vm.taskname
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

            if( vm.myflow !== -1 )
            {
                get_data.myflow=1;
            }
            if( vm.mytask !== -1 )
            {
                get_data.mytask=1;
            }
            if( vm.mylink !== -1 )
            {
                get_data.mylink=1;
            }
            get_data.bpmonly = 1;
            vm.loadover = false;
            if (Object.keys(get_data).length != 0){
                $http({
                    method:'GET',
                    url:'/api/job/task/' + '0',
                    params:get_data
                }).then(
                    function successCallback(response) {
                        vm.loadover = true;
                        if (response.data.stat){
                            vm.dealWithData(response.data.data.slice().reverse())
                            vm.data_Table = new ngTableParams({count:10}, {counts:[],data:response.data.data.reverse()});
                        }else {
                            swal('获取列表失败', response.data.info, 'error');
                        }
                    },
                    function errorCallback(response) {
                        swal('获取列表失败', response.status, 'error');
                    }
                );}

        };

        vm.reload();

        vm.dealWithData = function (data) {
          vm.tableData = []
          vm.exportDownloadStr = `<tr><td>BPM单号</td><td>任务名称</td><td>发起人</td><td>处理人</td><td>状态</td><td>发起时间</td><td>结束时间</td><td>耗时</td></tr>`
          data.forEach(items => {
            vm.tableData.push({
              extid: items.extid || '',
              alias: items.alias || '',
              user: items.user || '',
              handler: items.handler || '',
              status: vm.statuszh[items.status] || '',
              starttime: items.starttime || '',
              finishtime: items.finishtime || '',
              seftime: vm.seftime(items.starttime,items.finishtime) || '',
            })
          })
        }
    }
})();
