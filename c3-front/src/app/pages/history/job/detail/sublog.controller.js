(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('HistoryJobDetailSublogController', HistoryJobDetailSublogController);

    function HistoryJobDetailSublogController($uibModalInstance,$scope,$interval, $state, $http, repoData, subtaskuuid, taskuuid, salve, genericService) {

        var vm = this;
        vm.seftime = genericService.seftime
        vm.treeid = $state.params.treeid;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.taskuuid = taskuuid;
        vm.logaddr = salve;
        vm.loguuid = taskuuid+subtaskuuid+repoData.subtask_type;

        vm.statuszh = { "": "等待执行", "success": "执行成功", "fail": "执行失败", "decision": "执行失败", "running": "执行中", "ignore": "忽略" }
        vm.statuscolor = { "": "#aaa", "success": "green", "fail": "red", "decision": "red", "running": "orange" }
        vm.pluginname = { "approval": "审批", "cmd": "远程命令", "scp": "同步文件" }

        vm.reload = function () {
            $http.get('/api/job/subtask/' + vm.treeid + "/" + taskuuid +"/"+subtaskuuid).then(
                function successCallback(response){
                    if (response.data.stat){
                        vm.taskInfo = response.data.data;
                        $scope.statucolor = { "color": vm.statuscolor[vm.taskInfo.status] }
                        if( vm.taskInfo.status == 'success' || vm.taskInfo.status == 'fail')
                        {
                            $interval.cancel(reRun);
                        }
                    }else{
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response){
                    swal('获取信息失败', response.status, 'error' );
                });
        };

        vm.reload();
        var reRun = $interval(function () {
            vm.reload();
        }, 5000);

        $scope.$on('$destroy', function(){
            $interval.cancel(reRun);
        });

}})();
