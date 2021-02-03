(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('BusinessCrontabCreateController', BusinessCrontabCreateController);

    function BusinessCrontabCreateController($uibModalInstance,$scope,$state,$http, resoureceService,reloadhome, cronData, edit, jobData, $injector) {

        var vm = this;
        var toastr = toastr || $injector.get('toastr');
        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.treeid = $state.params.treeid;
        vm.edit = edit
        $scope.selectedjob = "";
        $scope.mutex = '';
        vm.cronlockstr = '';   
        vm.postcronData = {
            "name": "",
            "jobuuid": "",
            "cron":"",
            "mutex": "",
        };

        vm.createCron = function(){

            if(!$scope.cronTabname){
                toastr.error( '任务名称不能为空' )
                return
            }else if(!$scope.selectedjob){
                toastr.error( '指定作业不能为空' )
                return
            }

            if ($scope.cronlock){
                $scope.mutex = vm.cronlockstr
            }
            vm.postcronData = {
                "name": $scope.cronTabname,
                "jobuuid": $scope.selectedjob,
                "cron":$scope.cronrule,
                "mutex": $scope.mutex,
            };
            if (edit){
                resoureceService.work.changeCron([vm.treeid, cronData.id],vm.postcronData, null).finally(function(){
                    vm.cancel();
                    reloadhome();
                });
            }else {
                resoureceService.work.createCron([vm.treeid],vm.postcronData, null).finally(function(){
                    vm.cancel();
                    reloadhome();
                });
            }
        };

        vm.makeStr = function () {
             var text = "";
                var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

                for( var i=0; i < 5; i++ )
                    text += possible.charAt(Math.floor(Math.random() * possible.length));
                return text;
        };

        vm.getAllJobs = function () {
            $http.get('/api/job/jobs/'  + vm.treeid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        $scope.allJobs = []
                        angular.forEach(response.data.data, function (d, index) {
                            if( d.hasvariable == 0 )
                            {
                                $scope.allJobs.push(d)
                            }
                        });
                    }else {
                        $scope.dataready = false;
                        toastr.error( "获取作业信息失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取作业信息失败: " + response.status )
                });
        };

        vm.getAllJobs();

        vm.cronlockstr = vm.makeStr(); 
        if (edit){
            $scope.cronTabname = cronData.name;
            $scope.cronrule  = cronData.cron;
            if (cronData.mutex){
                $scope.cronlock = true;
                vm.cronlockstr = cronData.mutex;
            }
            $scope.selectedjob = cronData.jobuuid;

        }
        if (jobData){
            $scope.cronTabname = jobData.name;
            $scope.selectedjob = jobData.uuid;
        }
    }
})();

