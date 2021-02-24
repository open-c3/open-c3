(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('FileController', FileController);

    function FileController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, $injector) {

        var vm = this;

        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.getMe = function () {
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.createuser = data.email;
            });
        };

        $('#createstart').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.createStart = result;
            $scope.$apply();
        });

        vm.Reset = function () {
            vm.filename = "";
            vm.createuser = "";
            vm.createStart = "";
            vm.createEnd = "";
            vm.reload()
        };

        $('#createend').datetimepicker({
            format: 'YYYY-MM-DD',
            locale: moment.locale('zh-cn')
        }).on('dp.change', function (e) {
            var result = new moment(e.date).format('YYYY-MM-DD');
            vm.createEnd= result;
            $scope.$apply();
        });


        vm.bytesToSize = function(bytes) {
            if (bytes === 0) return '0 B';
            var k = 1000, // or 1024
                sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
                i = Math.floor(Math.log(bytes) / Math.log(k));

           return (bytes / Math.pow(k, i)).toPrecision(3) + ' ' + sizes[i];
        }

        vm.reload = function(){
            vm.loadover = false
            $http.get('/api/job/fileserver/' + vm.treeid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        var result = [];
                        angular.forEach( response.data.data.reverse(), function (value, key) {
                            if(vm.createuser && value["create_user"] != vm.createuser){
                                return true;
                            }
                            if(vm.filename && value["name"].indexOf(vm.filename) < 0 ){
                                return true;
                            }
                            if(vm.createStart){
                                var start_time = new Date(vm.createStart).getTime();
                                var create_time = new Date(value["create_time"]).getTime();
                                if (create_time <= start_time) {
                                    return true;
                                }
                            }
                            if(vm.createEnd){
                                var finish_time = new Date(vm.createEnd).getTime();
                                var create_time = new Date(value["create_time"]).getTime();
                                if (finish_time <= create_time) {
                                    return true;
                                }
                            }
                            result.push(value);
                        });
                        vm.loadover = true
                        vm.file_Table = new ngTableParams({count:10}, {counts:[],data:result});
                    }else {
                        swal({ title:'获取文件列表失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response ){
                    swal({ title:'获取文件列表失败', text: response.status, type:'error' });
                });


        };

        vm.deleteFile = function (idx) {
            resoureceService.file.delete([vm.treeid, idx], null, null)
                .then(function (repo) {
                    if (repo.stat){
                        vm.reload();
                    }
                    else
                    {
                        toastr.error("删除失败:" + repo.info)
                    }
                })

        };

        $scope.upForm = function () {
            var form = new FormData();
            var file = document.getElementById("choicefiles").files[0];
            form.append('file', file);
            $http({
                method: 'POST',
                url: '/api/job/fileserver/'+ vm.treeid,
                data: form,
                headers: {'Content-Type': undefined},
                transformRequest: angular.identity
            }).success(function (data) {
                if (data.stat){
                    vm.reload()
                }
                else
                {
                    toastr.error("上传失败:" + data.info)
                }
            }).error(function (data) {
                toastr.error("上传失败:" + data)
            })
        };
        vm.clickImport = function () {
            document.getElementById("choicefiles").click();
        };

 

        vm.manageToken = function () {
            $uibModal.open({
                templateUrl: 'app/pages/business/file/token.html',
                controller: 'tokenController',
                controllerAs: 'token',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {}
            });
        };
        vm.reload();
    }

})();
