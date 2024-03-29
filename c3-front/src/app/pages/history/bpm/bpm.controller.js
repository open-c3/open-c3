(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryBpmController', HistoryBpmController);
    function HistoryBpmController($filter, $timeout, $state, $http, $scope, ngTableParams, genericService ) {

        var vm = this;

        vm.seftime = genericService.seftime
        vm.myflow = $state.params.type.indexOf('myflow')
        vm.mytask = $state.params.type.indexOf('mytask')
        vm.mylink = $state.params.type.indexOf('mylink')

        vm.statuszh = { "": "等待执行", "success": "执行成功", "fail": "执行失败", "refuse": "审批拒绝", "decision": "执行失败", "running": "执行中", "ignore": "忽略", "waiting": "等待中" }

        var today = new Date();
        var thirtyDaysAgo = new Date(today.getTime() - (30 * 24 * 60 * 60 * 1000));
        var nowTime = $filter('date')(thirtyDaysAgo, "yyyy-MM-dd");
        vm.starttime = nowTime;
        vm.treeid = $state.params.treeid;
        $scope.searchStatus = "";
        vm.statusOption = [
          { status: null, name: "C3T.全部" },
          { status: "fail", name: "C3T.失败" },
          { status: "success", name: "C3T.成功" },
          { status: "refuse", name: "C3T.审批拒绝" },
          { status: "running", name: "C3T.执行中" },
          { status: "waiting", name: "C3T.等待" }
        ];
        vm.choiceJob = [];
        vm.taskname = '';
        vm.keyword = ''
        vm.bpmuuid = ''
        vm.selectedStatus = ''
        vm.selectTaskname = '';
        vm.downloadTitleMap = {
          extid: 'BPM单号',
          alias: '任务名称',
          user: '发起人',
          handler: '处理人',
          status: '状态',
          starttime: '发起时间',
          finishtime: '结束时间',
          seftime: '耗时',
        };

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
            vm.bpmuuid = ''
            vm.selectTaskname = ''
            vm.keyword = ''
            vm.selectedStatus = ''
            vm.reload()
        };

        vm.getHobNameData = function () {
          $http.get('/api/job/bpm/menu' ).success(function(data){
            if (data.stat) {
              vm.choiceJob = data.data
            }
          })
        }

        vm.getHobNameData();

        vm.handleJobChange = function (value) {
          vm.selectTaskname = value
        }
        vm.handleStatusChange = function (value) {
          vm.searchStatus = value
        }

        vm.reload = function () {
            var get_data = {};
            if (vm.selectTaskname){
                get_data.alias=vm.selectTaskname
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
            if(vm.bpmuuid){
              get_data.bpmuuid=vm.bpmuuid
            }
            if(vm.keyword){
              get_data.keyword=vm.keyword
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
                            vm.downloadData = response.data.data
                            const hasfilterData = response.data.data.map(item => {
                              item['statuszhMap'] = vm.statuszh[item.status]|| '';
                              item['seftimeCount'] = vm.seftime(item.starttime,item.finishtime) || '';
                              return item
                            })
                            vm.data_Table = new ngTableParams({count:10}, {counts:[],data:hasfilterData.reverse()});
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

        vm.downloadFunc = function (fileName) {
          const downLoadArr = [];
          vm.downloadData.map(item => {
            item.status = vm.statuszh[item.status]|| '';
            item.seftime =  vm.seftime(item.starttime,item.finishtime) || '';
            const newData = {};
            angular.forEach(vm.downloadTitleMap, function (key,value) { newData[key] = item[value]})  
            downLoadArr.push(newData)
          });
          const workbook = XLSX.utils.book_new();
          const worksheet = XLSX.utils.json_to_sheet(downLoadArr);
          XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');
          const wbout = XLSX.write(workbook, { bookType: 'xlsx', type: 'array', stream: true });
          const blob = new Blob([wbout], { type: 'application/octet-stream' });
          saveAs(blob, fileName);
        }
    }
})();
