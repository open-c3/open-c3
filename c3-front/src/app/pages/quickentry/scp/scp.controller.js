(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DistributeController', DistributeController);

    function DistributeController($scope,$filter, $state, $http,$window,$uibModal, $timeout,treeService,resoureceService, scriptId, $injector) {

        var vm = this;
        $scope.dataready = true;
        var toastr = toastr || $injector.get('toastr');
        vm.choiceNode = [];
        vm.choiceAllFiles = [];
        vm.scriptid = scriptId.getter();
        scriptId.del();
        vm.treeid = $state.params.treeid;
        vm.scriptHide = true;
        $scope.srcShow = false;
        $scope.choiceShow = false;

        vm.postdata = { deployenv: 'always', action: 'always', batches: 'always' };

        $scope.userShow = false;
        $scope.chownShow = false;
        $scope.dstServerShow = false;
        $scope.srcServerShow = false;
        $scope.scp_dir = true;
        $scope.title = "目标路径以'/'结尾代表一个目录，不以‘/’结尾表示一个文件。如：/tmp/表示将文件保存到此目录下，/tmp/test.txt表示将文件保存到此目录下，文件名为test.txt";
        $scope.srcDate = {
            'sp':'',
            'src_type':'',
            'src':'',
        };
        $scope.dstDate = {
            'name':'',
            'user':'',
            'dst_type':'',
            'dst':'',
            'dp':'',
            'chown':null,
            'chmod':null,
            'timeout':'60',
        };
        $scope.copySrcdata = angular.copy($scope.srcDate);
        var ssss = $filter('date')(new Date, "yyyyMMddHHmmss") + $filter('date')(new Date, "sss");
        vm.s_name = "快速分发文件-" + ssss;
        $scope.dstDate.name = vm.s_name;
        treeService.sync.then(function(){      // when the tree was success.
            vm.nodeStr = treeService.selectname();  // get tree name
        });

        vm.getProUser = function () {
            if (vm.treeid){
                $http.get('/api/job/userlist/' + vm.treeid).then(

                    function successCallback (response) {
                        if (response.data.stat){
                            $scope.allProUsers= response.data.data;
                        }else {
                            toastr.error( "获取执行账户列表失败："+response.data.info )
                        }
                    },
                    function errorCallback () {
                        toastr.error( "获取执行账户列表失败："+response.status )
                    }
                );
            }
        };
        vm.addProUser = function () {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/addUser.html',
                controller: 'AddUserController',
                controllerAs: 'addUser',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},
                    reloadUser : function () { return vm.getProUser}
                }
            });
        };

        // vm.check_dir = function () {
        //     if ($scope.dstDate.dp.endsWith("/")) {
        //         $scope.scp_dir = true;
        //     }else{
        //         $scope.scp_dir = false;
        //     };
        // };
        
        vm.delChoice = function (id, name) {
            if (id >=0){
                $scope.choiceResult.splice(id, 1);
                angular.forEach(vm.choiceNode, function (data, index) {
                    if (data == name){
                        vm.choiceNode.splice(index, 1);
                    }
                });
                $scope.dstDate.dst = vm.choiceNode.join(",")
            }
        };

        // 选择源地址
        vm.choiceSourceServer = function () {
            var openChoice = $uibModal.open({
                templateUrl: 'app/components/machine/choiceMachine.html',
                controller: 'ChoiceController',
                controllerAs: 'choice',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},

                }
            });
            openChoice.result.then(
                function (result) {
                    if (result.length != 0){
                        if (result.length >0){
                            if (result[0].plugin){
                                $scope.copySrcdata.src_type = "group";
                                $scope.copySrcdata.src = result[0].id;
                                $scope.srouceServerResult ="组： "+result[0].name
                            }else{
                                $scope.copySrcdata.src_type = "builtin";
                                $scope.srouceServerResult = "节点： ";
                                vm.choiceNode.splice(0, vm.choiceNode.length);
                                angular.forEach(result, function (data) {
                                    vm.choiceNode.push(data);
                                    $scope.srouceServerResult += data +","
                                });
                                $scope.copySrcdata.src = vm.choiceNode.join(",")
                            }
                        }
                    }
                },function (reason) {
                    console.log("error reason", reason)
                }
            );

        };
        // 选择目标地址
        vm.choiceServer = function () {
            var openChoice = $uibModal.open({
                templateUrl: 'app/components/machine/choiceMachine.html',
                controller: 'ChoiceController',
                controllerAs: 'choice',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeId: function () { return vm.treeid},

                }
            });
            openChoice.result.then(
                function (result) {
                    if (result.length != 0){
                        $scope.choiceShow = true;
                        $scope.choiceResult = result;
                        if (result.length >0){
                            if (result[0].plugin){
                                $scope.choiceType = "分组类型";
                                $scope.dstDate.dst_type = "group";
                                $scope.dstDate.dst = result[0].id;
                                vm.choiceNode.splice(0, vm.choiceNode.length);
                                // angular.forEach(result, function (data) {
                                //     vm.choiceNode.push(data.id);
                                // });
                            }else{
                                $scope.choiceType = "节点类型";
                                $scope.dstDate.dst_type = "builtin";
                                vm.choiceNode.splice(0, vm.choiceNode.length);
                                angular.forEach(result, function (data, index) {
                                    vm.choiceNode.push(data);
                                });
                                $scope.dstDate.dst = vm.choiceNode.join(",")
                            }
                        }
                    }
                },function (reason) {
                    console.log("error reason", reason)
                }
            );
        };

        vm.choiceSourceFile = function () {
            vm.choiceSourceServer();
            $scope.srcShow = true;
            $scope.varShow = false;
            $scope.varData = null;
            $scope.shareResult = [];
            // $scope.copySrcdata = angular.copy($scope.srcDate);
        };

        vm.choiceVariable = function () {
            var openChoice = $uibModal.open({
                templateUrl: 'app/components/variable/choiceVar.html',
                controller: 'ChoiceVarController',
                controllerAs: 'choicevar',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {}
            });
            openChoice.result.then(
                function (result) {
                    $scope.srcShow = false;
                    $scope.shareResult = [];
                    $scope.varShow = true;
                    $scope.varData = result;
                    $scope.copySrcdata.src_type = "ci";
                    $scope.copySrcdata.sp = result.version;
                    $scope.copySrcdata.src = result.ci;
                },function (reason) {
                    console.log("error reason", reason)
                }
            ); 
        };

        vm.choiceShareFiles = function () {
            var openChoice = $uibModal.open({
                templateUrl: 'app/pages/business/file/choiceFile.html',
                controller: 'ChoiceFileController',
                controllerAs: 'choicefile',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {}
            });
            openChoice.result.then(
                function (result) {
                    if (result.length != 0){
                        $scope.varShow = false;
                        $scope.srcShow = false;
                        $scope.shareResult = result;
                        // $scope.copySrcdata = angular.copy($scope.srcDate);
                        $scope.copySrcdata.sp = result[0].name;
                        $scope.copySrcdata.src_type = "fileserver";
                    }
                },function (reason) {
                    console.log("error reason", reason)
                }
            );
        };

        vm.runLog = function(d){
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/taskDetail.html',
                controller: 'JobDetailController',
                controllerAs: 'jobDetail',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    repoData : function () { return d}
                }
            });
        };

        vm.postData = function () {
            if($scope.copySrcdata.src_type){
                if($scope.copySrcdata.src_type != "fileserver" && !$scope.copySrcdata.src){
                    swal({
                        title:"请选择源服务器",
                        type:'error'
                    });
                    $scope.srcServerShow = true;
                }else {
                    $scope.srcServerShow = false;
                }
            }else {
                // if (){}
                $scope.srcServerShow = true;
                // alert("请选择源服务器");
                swal({
                    title:"请选择源服务器",
                    type:'error'
                });
                return
            }

            if ($scope.dstUser){
                $scope.dstDate.user = $scope.dstUser.username;
                $scope.userShow = false;
            }else {
                $scope.userShow = true;
            }

            if ($scope.fileChown){
                $scope.dstDate.chown = $scope.fileChown.username;
                $scope.chownShow = false;
            }else {
                $scope.chownShow = true;
            }

            if($scope.dstDate.dst){
                $scope.dstServerShow = false;
            }else {
                $scope.dstServerShow = true;
                swal({
                    title:"请选择目标服务器",
                    type:'error'
                });
                return
            }
            $scope.dstDate.timeout = parseInt($scope.dstDate.timeout);
            var post_data = $.extend($scope.dstDate, $scope.copySrcdata);

            post_data.deployenv = vm.postdata.deployenv
            post_data.action = vm.postdata.action
            post_data.batches = vm.postdata.batches

            resoureceService.work.scp(vm.treeid, post_data, null)
                .then(function (repo) {
                    if (repo.stat){
                        vm.runLog(repo.data);
                        // vm.reloadPage();
                        $scope.shareResult = [];
                        $scope.varData = null;
                        $scope.srcDate = {
                            'sp':'',
                            'src_type':'',
                            'src':'',
                        };
                        $scope.dstDate = {
                            'name':'',
                            'user':'',
                            'dst_type':'',
                            'dst':'',
                            'dp':'',
                            'chown':null,
                            'chmod':null,
                            'timeout':'60',
                        };
                        $scope.copySrcdata = angular.copy($scope.srcDate);
                        $scope.dstUser = "";
                        $scope.fileChown = "";
                    }else{
                        toastr.error( "提交任务失败:" + repo.info )
                    }
                }, function (repo) {
                    toastr.error( "提交任务失败:" + repo )

                })


        };

        vm.openDetail = function(d){
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/taskDetail.html',
                controller: 'JobDetailController',
                controllerAs: 'jobDetail',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    repoData : function () { return d}
                }
            });
        };
        vm.getProUser();

}})();
