(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('JobDetailController', JobDetailController);

    function JobDetailController($uibModalInstance,$scope,$timeout, $state, $http,$window,$uibModal, repoData, genericService, $interval, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.loguuid = repoData.loguuid;      // 日志的uuid
        vm.jobuuid = repoData.uuid;         // 当前执行任务的uuid
        vm.jobaddr = repoData.slave;
        vm.seftime = genericService.seftime
        vm.loadover = false;
        vm.pluginname = { "plugin_approval": "审批", "plugin_cmd": "远程命令", "plugin_scp": "同步文件" }
        var toastr = toastr || $injector.get('toastr');
        vm.reload = function () {
            $http.get('/api/job/task/' + vm.treeid + "/" + vm.jobuuid).then(
                function successCallback(response){
                    if (response.data.stat){
                        vm.taskInfo = response.data.data;
                        if (vm.taskInfo.status == "fail" ){
                            vm.jobState = "执行失败";
                            $scope.statucolor = {
                                "color": "red",
                                "font-weight": "bold"
                            };
                        }else if(vm.taskInfo.status == "success" ){
                            vm.jobState = "执行成功";
                            $scope.statucolor = {
                                "color": "green",
                                "font-weight": "bold"
                            };
                        }
                        if (vm.taskInfo.status == "fail" || vm.taskInfo.status ==  "success"){

                            vm.loadover = true;
                            $interval.cancel(reRun);
                        }else {
                            vm.jobState = "执行中";
                            $scope.statucolor = {
                                "color": "#f19301",
                                "font-weight": "bold"
                            };
                        }
                    }else{
                        toastr.error("获取任务状态信息失败:"+response.data.info)
                    }

                },
                function errorCallback (response){
                    toastr.error("获取任务状态信息失败:"+response.status)

                });
        };

        vm.reload();

        var reRun = $interval(function () {
            vm.reload();
        }, 2000);

        $scope.$on('$destroy', function(){
            $interval.cancel(reRun);
        });
}})();
