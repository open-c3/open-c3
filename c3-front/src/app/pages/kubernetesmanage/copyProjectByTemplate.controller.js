(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CopyProjectByTemplateXXController', CopyProjectByTemplateXXController);

    function CopyProjectByTemplateXXController($http, $uibModalInstance, $scope, resoureceService, treeid, reload, sourcename, cancel, $injector, clusterinfo, type, name, namespace ) {

        var vm = this;
        vm.status = 0
        $scope.projectname = sourcename
        var toastr = toastr || $injector.get('toastr');

        vm.containerlist = [];
        vm.templatelist = [];
        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/app/flowlineinfo?ticketid=" + clusterinfo.id + "&type=" + type + "&name=" + name + "&namespace=" + namespace  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.containerlist = data.data;
                } else { 
                    toastr.error("加载容器列表失败:" + data.info)
                }
            });
            $http.get("/api/ci/group/0" ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.templatelist = data.data;

                    angular.forEach(vm.templatelist, function (value, key) {
                        if( value.name ==  "kubernetes发布模版" )
                        {
                            vm.templateid = value.id;
                        }
                   });
 
                } else { 
                    toastr.error("加载容器列表失败:" + data.info)
                }
            });
 
        };
        vm.reload();

 

        vm.cancel = function(){ $uibModalInstance.dismiss(); };
        vm.add = function(){

            var container = {};
            angular.forEach(vm.containerlist, function (value, key) {
                if( value.id ==  vm.containerid )
                {
                    container = value;
                }
            });
 
            var sourceid = vm.templateid;

//TODO 检查container 和sourceid。数据不全要报错
            var s = 0
            if ( vm.status )
            {
                s = 1
            }

            var postData = {
                "name": $scope.projectname,
                "sourceid": sourceid,
                "status": s,

                "ci_type": "kubernetes",
                "ci_type_ticketid": clusterinfo.id,
                "ci_type_kind": type,
                "ci_type_namespace": namespace,
                "ci_type_name": name,
                "ci_type_container": container.container,
                "ci_type_repository": container.repository,
                "ci_type_dockerfile": "dockerfile",
                "ci_type_dockerfile_content": "",
            };
            $http.post('/api/ci/group/' + treeid , postData ).success(function(data){
                vm.install = { username: 'root' };
                    if(data.stat == true) {
                        var toid = data.id

                        $http.post('/api/job/jobs/' + treeid  + '/copy/byname', { fromname: '_ci_' + sourceid+'_', toname: '_ci_' + toid + '_', fromprojectid: 0 } ).success(function(data){
                            vm.install = { username: 'root' };
                                if(data.stat == true) {
                                    $http.post('/api/jobx/group/' + treeid  + '/copy/byname', { fromname: '_ci_test_' + sourceid+'_', toname: '_ci_test_' + toid + '_', fromprojectid: 0 } ).success(function(data){
                                        vm.install = { username: 'root' };
                                            if(data.stat == true) {
                                                $http.post('/api/jobx/group/' + treeid  + '/copy/byname', { fromname: '_ci_online_' + sourceid+'_', toname: '_ci_online_' + toid + '_', fromprojectid: 0 } ).success(function(data){
                                                    vm.install = { username: 'root' };
                                                        if(data.stat == true) {
                                                            vm.cancel();
                                                            cancel();
                                                            reload();
                                                        } else { toastr.error( "提交失败:" + data.info ); }
                                                });
                                            } else { toastr.error( "提交失败:" +data.info ); }
                                    });
                                } else { toastr.error( "提交失败:" + data.info ); }
                        });
                    } else { toastr.error("提交失败:" + data.info ); }
            });
        };
    }
})();

