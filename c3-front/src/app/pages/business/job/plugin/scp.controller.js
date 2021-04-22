(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('scpJobController', scpJobController);

    function scpJobController($scope,$filter, $state, $http,$uibModalInstance,$window,$uibModal, $timeout,treeService,resoureceService, scriptId, editData) {

        var vm = this;
        $scope.dataready = true;
        vm.choiceNode = [];
        vm.choiceAllFiles = [];
        vm.scriptid = scriptId.getter();
        scriptId.del();
        vm.treeid = $state.params.treeid;
        vm.scriptHide = true;
        $scope.srcShow = false;
        $scope.varShow = false;
        $scope.choiceShow = false;

        vm.postdata = { deployenv: 'always', action: 'always', batches: 'always' };

        $scope.userShow = false;
        $scope.chownShow = false;
        $scope.dstServerShow = false;
        $scope.srcServerShow = false;
        $scope.scp_dir = true;
        $scope.title = "目标路径以'/'结尾代表一个目录，不以‘/’结尾表示一个文件。如：/tmp/表示将文件保存到此目录下，/tmp/test.txt表示将文件保存到此目录下，文件名为test.txt";
        $scope.varData = {
            'ci':null,
            'version':null
        };
        $scope.srcDate = {
            'sp':'',
            'src_type':'',
            'src':'',
        };
        $scope.dstDate = {
            'plugin_type':'scp',
            'name':'',
            'user':'',
            'dst_type':'',
            'dst':'',
            'dp':'',
            'chown':'',
            'chmod':'755',
            'timeout':'60',
            'pause':'',
        };
        $scope.copySrcdata = angular.copy($scope.srcDate);
        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.getProUser = function () {
            if (vm.treeid){
                $http.get('/api/job/userlist/' + vm.treeid).then(

                    function successCallback (response) {
                        if (response.data.stat){
                            $scope.dataready = true;
                            $scope.allProUsers= response.data.data;
                        }else {
                            $scope.dataready = false;
                            $scope.dataerror = "获取账户信息失败："+response.data.info;
                        }
                    },
                    function errorCallback () {
                        $scope.dataready = false;
                        $scope.dataerror = "获取账户信息失败："+response.status;
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
                                $scope.srouceServerResult ="组： "+result[0].name;
                                $scope.copySrcdata.src_group = result[0].name;
                            }else{
                                $scope.copySrcdata.src_type = "builtin";
                                $scope.srouceServerResult = "节点： ";
                                vm.choiceNode.splice(0, vm.choiceNode.length);
                                angular.forEach(result, function (data) {
                                    vm.choiceNode.push(data);
                                    $scope.srouceServerResult += data+ ",";
                                });
                                $scope.copySrcdata.src = vm.choiceNode.join(",")
                            }
                        }
                        else if(result.variable){
                            $scope.copySrcdata.src_type = "variable";
                            $scope.copySrcdata.src = result.variable;
                            $scope.srouceServerResult = result.variable;
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
                            }
                            else {
                                $scope.choiceType = "节点类型";
                                $scope.dstDate.dst_type = "builtin";
                                vm.choiceNode.splice(0, vm.choiceNode.length);
                                angular.forEach(result, function (data) {
                                    vm.choiceNode.push(data);
                                });
                                $scope.dstDate.dst = vm.choiceNode.join(",")
                            }
                        }
                        else if(result.variable){
                            $scope.dstDate.dst_type = "variable";
                            $scope.choiceType = "变量";
                            $scope.choiceResult = [result];
                            $scope.dstDate.dst = result.variable;
                            vm.choiceNode.push(result.variable);
                        }

                    }
                },function (reason) {
                    console.log("error reason", reason)
                }
            );
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
                    if (result.length != 0){
                        $scope.srcShow = false;
                        $scope.shareResult = [];
                        $scope.varShow = true;
                        $scope.varData = result;
                        $scope.copySrcdata.src = result.ci;
                        $scope.copySrcdata.src_type = "ci";
                        $scope.copySrcdata.sp = result.version;
                    }
                },function (reason) {
                    console.log("error reason", reason)
                }
            );
        };
        vm.choiceSourceFile = function () {
            vm.choiceSourceServer();
            $scope.varShow = false;
            $scope.srcShow = true;
            $scope.copySrcdata.sp = '';
            $scope.copySrcdata.src = '';
            $scope.srouceServerResult = "";
            $scope.shareResult = [];
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
                        $scope.srcShow = false;
                        $scope.varShow = false;
                        $scope.shareResult = result;
                        console.log(result[0].name);
                        console.log(typeof result[0]);
                        $scope.copySrcdata.sp = result[0].name;
                        $scope.copySrcdata.src_type = "fileserver";
                        $scope.copySrcdata.src = "";
                    }
                },function (reason) {
                    console.log("error reason", reason)
                }
            ); // end result
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

        vm.returnData = function () {
            if($scope.copySrcdata.src_type){
                if($scope.copySrcdata.src_type != "fileserver" && !$scope.copySrcdata.src){
                    alert("请选择源服务器");
                    $scope.srcServerShow = true;
                }else {
                    $scope.srcServerShow = false;
                }
            }else {
                $scope.srcServerShow = true;
                alert("请选择源服务器");
            }

            if ($scope.dstUser){
                $scope.dstDate.user = $scope.dstUser;
                $scope.userShow = false;
            }else {
                $scope.userShow = true;
            }

            if ($scope.fileChown){
                $scope.dstDate.chown = $scope.fileChown;
                $scope.chownShow = false;
            }else {
                $scope.chownShow = true;
            }

            if($scope.dstDate.dst){
                $scope.dstServerShow = false;
            }else {
                $scope.dstServerShow = true;
                alert("请选择目标服务器");
                return
            }
            $scope.dstDate.timeout = parseInt($scope.dstDate.timeout);
            var post_data = $.extend($scope.dstDate, $scope.copySrcdata);
            post_data.deployenv = vm.postdata.deployenv;
            post_data.action = vm.postdata.action;
            post_data.batches = vm.postdata.batches;
            $uibModalInstance.close(
                post_data
            );
        };

        vm.getProUser();

        if (editData){
            $scope.editmode = true;
            $scope.dstDate.name = editData.name;

            vm.postdata = { deployenv: editData.deployenv, action: editData.action, batches: editData.batches };

            if (editData.src_type == "fileserver"){
                $scope.shareResult = [{"name":editData.sp}];
                $scope.copySrcdata.sp = editData.sp;
                $scope.copySrcdata.src_type = editData.src_type;
            }else if(editData.src_type == "ci"){
                $scope.varShow = true;
                $scope.varData = {'version':editData.sp, 'ci':editData.src};
                $scope.copySrcdata.sp = editData.sp;
                $scope.copySrcdata.src_type = editData.src_type;
                $scope.copySrcdata.src = editData.src;
            }
            else {
                $scope.srcShow = true;
                $scope.shareResult = [];
                $scope.copySrcdata.sp = editData.sp;
                $scope.copySrcdata.src_type = editData.src_type;
                $scope.copySrcdata.src = editData.src;
                if (editData.src_type == "group"){
                    $scope.srouceServerResult ="组： "+ editData.src_group;
                }else if(editData.src_type == "builtin"){
                    $scope.srouceServerResult = "节点： " + editData.src;
                    if (editData.dp.endsWith("/")) {
                        $scope.scp_dir = true;
                        if (editData.scp_delete == 1) {$scope.dstDate.scp_delete = true;}
                    };
                }else if(editData.src_type == "variable"){
                    $scope.srouceServerResult = editData.src;
                }
            }
            $scope.dstUser = editData.user;
            $scope.dstDate.user = editData.user;
            $scope.dstDate.dp = editData.dp;
            $scope.dstDate.dst_type = editData.dst_type;
            // dp:"/tmp/ttt"
            // dst:"10.60.1.1"
            // dst_type:"builtin"
            $scope.nodeType = editData.dst_type;
            $scope.choiceResult = [];
            if ($scope.nodeType == "group"){
                $scope.choiceType = "分组类型";
                // choiceResult
                $http.get('/api/job/nodegroup/' + vm.treeid +"/"+ editData.dst).then(
                    function successCallback (response) {
                        if (response.data.stat){
                            $scope.choiceResult.push({"name":response.data.data.name});
                        }else {
                        }
                    },
                    function errorCallback () {
                    }
                );
                vm.choiceNode.push(editData.dst);
                $scope.dstDate.dst = editData.dst;
                $scope.choiceShow = true;

            }else if($scope.nodeType == "builtin"){
                $scope.choiceType = "节点类型";
                angular.forEach(editData.dst.split(","), function (ip, index) {
                    $scope.choiceResult.push(ip);
                    vm.choiceNode.push(ip);
                });
                $scope.choiceShow = true;
                $scope.dstDate.dst = vm.choiceNode.join(",");

            }else if($scope.nodeType == "variable"){
                $scope.choiceType = "变量";
                // angular.forEach(editData.dst.split(","), function (ip, index) {
                //     $scope.choiceResult.push(ip);
                //     vm.choiceNode.push(ip);
                // });
                $scope.choiceResult.push({"variable":editData.dst});
                $scope.choiceShow = true;
                $scope.dstDate.dst = editData.dst;

            }

            $scope.dstDate.dp = editData.dp;
            $scope.fileChown = editData.chown;
            $scope.dstDate.chmod = editData.chmod;
            $scope.dstDate.timeout = parseInt(editData.timeout);
            $scope.dstDate.pause = editData.pause;

        }
}})();
