(function(){
    'use strict';

    angular
        .module('openc3')
        .controller('tokenController', tokenController);

        function tokenController($rootScope, $scope,$injector,$uibModalInstance, $http, $state, md5,resoureceService) {

            var vm = this;
            vm.allToken = [];
            vm.cancel = function(){ $uibModalInstance.dismiss()};
            vm.hosturl = window.location.host;
            vm.treeid = $state.params.treeid;
            vm.newToken = "";
            vm.tokenDis = "";
            vm.jobname = "";
            vm.isjob = false;
            var toastr = toastr || $injector.get('toastr');
            vm.getToken = function () {
                $http.post('/api/job/token/'+vm.treeid+'/info').then(
                    function successCallback (response) {
                        if (response.data.stat){
                            vm.allToken = response.data.data;
                        }else {
                            toastr.error( "获取token信息失败:" + response.data.info )
                        }
                    },
                    function errorCallback () {
                        toastr.error( "获取token信息失败:" + response.status )
                    }
                );
            };

            vm.getJObs = function () {
                $http.post('/api/job/third/option/jobname', {"project_id": vm.treeid}).then(
                    function successCallback (response) {
                        if (response.data.stat){
                            vm.allJobs = response.data.data;
                        }else {
                            toastr.error( "获取作业列表失败:" + response.data.info )
                        }
                    },
                    function errorCallback () {
                        toastr.error( "获取作业列表失败:" + response.status )
                    }
                );
            };

            vm.delToken = function (idx) {
                resoureceService.token.delete([vm.treeid, idx], null,  null)
                    .then(function (repo) {
                        if (repo.stat){
                            vm.getToken();
                        }else {
                            toastr.error( "删除token失败:" + repo.info )
                        }
                    })
            };
            vm.randomString = function () {
                return md5.createHash(String(new Date().getTime()))
            };
            vm.initToken = function () {
                vm.getToken();
                vm.newToken = vm.randomString();
                vm.tokenDis = "";
            };
            vm.initJOB = function () {
                vm.isjob = false;
                vm.jobname = "";
            };
            vm.showJob = function (isjob, jobname) {
                if (isjob == '1') {
                    return jobname;
                } else {
                    return "否";
                }
            };
            vm.addToken = function () {
                if (vm.newToken.length != 32){
                    swal({
                        title:"token长度不等于32字符",
                        type:'error'
                    });
                    return
                }
                if(!vm.tokenDis){
                    swal({
                        title:"token描述不能为空",
                        type:'error'
                    });
                    return
                }
                if(vm.isjob && !vm.jobname){
                    swal({
                        title:"请选择常用作业，或关闭调用job按钮",
                        type:'error'
                    });
                    return
                }
                $http.post('/api/job/token/'+vm.treeid, {"token":vm.newToken, "describe":vm.tokenDis, "isjob": vm.isjob, "jobname": vm.jobname}).then(
                    function successCallback (response) {
                        if (response.data.stat){
                            vm.initToken();
                            vm.initJOB();
                        }else {
                            vm.initToken();
                            vm.initJOB();
                        }
                    },
                    function errorCallback () {
                        vm.initToken();
                        vm.initJOB();
                    }
                );
            };

            vm.getToken();
            vm.getJObs();
            vm.newToken = vm.randomString();
        }

})();
