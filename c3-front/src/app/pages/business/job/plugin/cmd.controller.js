(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('scriptJobController', scriptJobController);

    function scriptJobController($scope,$filter, $state, $http,$window,$uibModal,$uibModalInstance, $timeout,treeService,resoureceService,treeId, editData, seq) {
        var vm = this;

        $scope.dataready = true;
        vm.choiceNode = [];
        vm.treeid = treeId;
        vm.scriptHide = true;
        $scope.choiceShow = false;
        $scope.s_timeout = '60';
        $scope.scriptType = "shell";
        $scope.scriptUnclick = false;
        if (!editData){$scope.s_name = "执行脚本_"+seq};

        vm.postdata = { deployenv: 'always', action: 'always', batches: 'always' };

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.getAllScript = function () {
            vm.scriptHide = true;
            if (vm.treeid){
                $http.get('/api/job/scripts/' + vm.treeid).success(function(data){
                    vm.scriptHide = true;
                    if (data.stat){
                        $scope.allScript = data.data;
                    }
                });
            }
        };

        vm.getProUser = function () {
            if (vm.treeid){
                $http.get('/api/job/userlist/' + vm.treeid).then(
                    function successCallback (response) {
                        if (response.data.stat){
                            $scope.dataready = true;
                            $scope.allProUsers = response.data.data;
                        }else {
                            $scope.dataready = false;
                            $scope.dataerror = "获取账户信息失败："+response.data.info;
                        }
                    },
                    function errorCallback () {
                        $scope.dataready = false;
                        $scope.dataerror = "获取账户信息失败：";
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

            }
        };

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
                                $scope.nodeType = "group";
                                vm.choiceNode.splice(0, vm.choiceNode.length);
                                angular.forEach(result, function (data) {
                                    vm.choiceNode.push(data.id);
                                });
                            }else {
                                $scope.choiceType = "节点类型";
                                $scope.nodeType = "builtin";
                                vm.choiceNode.splice(0, vm.choiceNode.length);
                                angular.forEach(result, function (data) {
                                    vm.choiceNode.push(data);
                                });
                            }
                        } else if(result.variable){
                            $scope.nodeType = "variable";
                            vm.dstServevar = result.variable;
                            $scope.choiceType = "变量类型";
                            $scope.choiceResult = [result];
                            vm.choiceNode = [];
                            vm.choiceNode.push(result.variable);
                        }
                    }
                },function (reason) {
                    console.log("error reason", reason)
                }
            );
        };

        vm.editorSh = function (data, re) {
            vm.shEditor = ace.edit("editor");
            var sheditor  = vm.shEditor;
            sheditor.setTheme("ace/theme/dracula");
            sheditor.session.setMode("ace/mode/sh");
            document.getElementById('editor').style.fontSize='14px';
            sheditor.setShowPrintMargin(false);
            sheditor.setHighlightActiveLine(false);
            if (data){
                sheditor.setValue(data);
            }
            if (re){
                sheditor.setReadOnly(true)
            }
            vm.leaveeditor();
        };
        vm.editorPy = function (data, re) {
            vm.pyEditor = ace.edit("editor");
            var pyeditor = vm.pyEditor;
            pyeditor.setTheme("ace/theme/dracula");
            pyeditor.session.setMode("ace/mode/python");
            document.getElementById('editor').style.fontSize='14px';
            document.getElementById('editor').style.font='14px';
            pyeditor.setShowPrintMargin(false);
            pyeditor.setHighlightActiveLine(false);
            if (data){
                pyeditor.setValue(data);
            }
            if (re){
                pyeditor.setReadOnly(true)
            }
            vm.leaveeditor();
        };

        vm.editorPerl = function (data, re) {
            vm.perlEditor = ace.edit("editor");
            var perleditor = vm.perlEditor;
            perleditor.setTheme("ace/theme/dracula");
            perleditor.session.setMode("ace/mode/perl");
            document.getElementById('editor').style.fontSize='14px';
            document.getElementById('editor').style.font='14px';
            perleditor.setShowPrintMargin(false);
            perleditor.setHighlightActiveLine(false);
            if (data){
                perleditor.setValue(data);
            }
            if (re){
                perleditor.setReadOnly(true)
            }
            vm.leaveeditor();
        };

        vm.editorPhp = function (data, re) {
            vm.phpEditor = ace.edit("editor");
            var phpeditor = vm.phpEditor;
            phpeditor.setTheme("ace/theme/dracula");
            phpeditor.session.setMode("ace/mode/perl");
            document.getElementById('editor').style.fontSize='14px';
            document.getElementById('editor').style.font='14px';
            phpeditor.setShowPrintMargin(false);
            phpeditor.setHighlightActiveLine(false);
            if (data){
                phpeditor.setValue(data);
            }
            if (re){
                phpeditor.setReadOnly(true)
            }
            vm.leaveeditor();
        };

        vm.editorBuildin = function (data, re) {
            vm.buildinEditor = ace.edit("editor");
            var buildineditor = vm.buildinEditor;
            buildineditor.setTheme("ace/theme/dracula");
            buildineditor.session.setMode("ace/mode/sh");
            document.getElementById('editor').style.fontSize='14px';
            document.getElementById('editor').style.font='14px';
            buildineditor.setShowPrintMargin(false);
            buildineditor.setHighlightActiveLine(false);
            if (data){
                buildineditor.setValue(data);
            }
            if (re){
                buildineditor.setReadOnly(true)
            }
            vm.leaveeditor();
        };

        vm.editorAuto = function (data, re) {
            vm.autoEditor = ace.edit("editor");
            var autoeditor  = vm.autoEditor;
            autoeditor.setTheme("ace/theme/dracula");
            autoeditor.session.setMode("ace/mode/sh");
            document.getElementById('editor').style.fontSize='14px';
            autoeditor.setShowPrintMargin(false);
            autoeditor.setHighlightActiveLine(false);
            if (data){
                autoeditor.setValue(data);
            }
            if (re){
                autoeditor.setReadOnly(true)
            }
            vm.leaveeditor();
        };

        vm.showmachinelist = 1;

        vm.leaveeditor = function() {
            vm.showmachinelist = 1;
            if($scope.scriptType == "buildin"){
                var cont = vm.buildinEditor.getValue();
                if( cont.search(/^#!kubectl\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!terraform\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!terraformv2\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!kubestar\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!awsecs\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!awsecsv2\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!awsecsv3\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!awsEcsService\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!sendemail\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!sendmesg\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!flowcaller\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!cdnrefresh\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!cdnrefreshv2\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!kubernetes\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!tsunamiudp\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!calltestenv\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!localbash\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!qaCallback\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!k8snscp\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#!flownscp\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
                if( cont.search(/^#![a-z0-9]+debug\b/) == 0 )
                {
                    vm.showmachinelist = 0;
                }
//                if( cont.search(/^#!elbShowv2\b/)    == 0 ) { vm.showmachinelist = 0; }
//                if( cont.search(/^#!elbOfflinev2\b/) == 0 ) { vm.showmachinelist = 0; }
//                if( cont.search(/^#!elbOnlinev2\b/)  == 0 ) { vm.showmachinelist = 0; }
//                if( cont.search(/^#!awsTargetGroup\b/)  == 0 ) { vm.showmachinelist = 0; }
                if( cont.search(/^#!bpmtask\b/)  == 0 ) { vm.showmachinelist = 0; }
                if( cont.search(/^#!null\b/) == 0     ) { vm.showmachinelist = 0; }
                if( cont.search(/^#!sleep\b/)  == 0   ) { vm.showmachinelist = 0; }
            }
        }

        vm.buildinSet = function( name ) {
            vm.editorBuildin( '#!' + name, false );
        }

        vm.scriptTypeEditor = {
            "shell": vm.editorSh,
            "python": vm.editorPy,
            "perl": vm.editorPerl,
            "php": vm.editorPhp,
            "buildin": vm.editorBuildin,
            "auto": vm.editorAuto,
        };

        vm.click = '';
        vm.scriptManual =function () {
            if (vm.click != "manual"){
                ace.edit("editor").setValue('');
                ace.edit("editor").setReadOnly(false);
                $scope.unClick = false;
                vm.editorSh(null, false);
                $scope.scriptType = "shell";
            }
            $scope.scriptUnclick = false;
            vm.scriptHide = true;
            vm.click = "manual";
        };

        vm.from = 'manual';
        vm.scriptClone =function () {
            if (vm.click != "clone"){
                vm.scriptHide = false;
                $scope.selectedScript = '';
                ace.edit("editor").setValue('');
                ace.edit("editor").setReadOnly(false);
                $scope.scriptType = "";
                vm.s_name = "";
            }
            vm.click = "clone";

        };

        vm.scriptLocal =function () {
            if (vm.click != "local"){
                vm.scriptHide = false;
                $scope.selectedScript = '';
                ace.edit("editor").setValue('');
                ace.edit("editor").setReadOnly(true);
                $scope.scriptType = "";
            }
            vm.click = "local";

        };
        vm.inputScript = function () {
            vm.selected_id = $scope.selectedScript.id;
            $http.get('/api/job/scripts/' + vm.treeid + "/" + vm.selected_id).success(function(data){
                if (data.stat){
                    var inputEdit = vm.scriptTypeEditor[data.data.type];
                    var scriptData = data.data;
                    if (vm.from == "clone"){
                        inputEdit(data.data.cont, false);

                    }else if (vm.from == "local"){
                        inputEdit(data.data.cont, true);
                        vm.s_name = scriptData.name;
                        $scope.localId = scriptData.id;
                    }
                    $scope.scriptType = data.data.type;
                }
            });
        };

        vm.returnSave = function (scriptForm) {
            var cont = '';
            if ($scope.scriptType == "shell"){
                cont = vm.shEditor.getValue();
            }else if($scope.scriptType == "python"){
                cont = vm.pyEditor.getValue();
            }else if($scope.scriptType == "perl"){
                cont = vm.perlEditor.getValue();
            }else if($scope.scriptType == "php"){
                cont = vm.phpEditor.getValue();
            }else if($scope.scriptType == "buildin"){
                cont = vm.buildinEditor.getValue();
                if( vm.showmachinelist == 0  )
                {
                    $scope.nodeType = 'builtin';
                    vm.choiceNode = [ 'openc3skipnode' ]
                }
            }else if($scope.scriptType == "auto"){
                cont = vm.autoEditor.getValue();
            }
            cont = cont.replace(/\r\n/g, "\n");
            if (!$scope.s_argv){
                $scope.s_argv = " "
            }
            if (!vm.from){
                alert("脚本来源不能为空!");
                return
            }else if (vm.choiceNode.length == 0){
                alert("所选机器不能为空!");
                return
            }else if(!$scope.scriptType){
                alert("脚本类型不能为空！");
                return
            }
            if(vm.from == 'local'){
                $scope.scriptType = 'cite';
                cont = $scope.localId;
            }
            var post_data ={
                'plugin_type':'cmd',
                'name': vm.s_name,
                'user': $scope.selectedUser,
                'node_type':$scope.nodeType,
                'node_cont':vm.choiceNode.join(","),
                'scripts_type':$scope.scriptType,
                'scripts_cont': cont,
                'scripts_argv': $scope.s_argv,
                'timeout': parseInt($scope.s_timeout),
                'pause': $scope.pause,
                'deployenv' : vm.postdata.deployenv,
                'action' : vm.postdata.action,
                'batches' : vm.postdata.batches
            };
            $uibModalInstance.close(
                post_data
            );

        };

        if (editData){
            vm.s_name = editData.name;
            $scope.selectedUser = editData.user;
            $scope.nodeType = editData.node_type;
            $scope.choiceResult = [];
            if ($scope.nodeType == "group"){
                $scope.choiceType = "分组类型";
                $http.get('/api/job/nodegroup/' + vm.treeid +"/"+ editData.node_cont).then(
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
                $scope.choiceShow = true;

            }else if($scope.nodeType == "builtin"){
                $scope.choiceType = "节点类型";
                angular.forEach(editData.node_cont.split(","), function (ip, index) {
                    $scope.choiceResult.push(ip);
                    vm.choiceNode.push(ip);
                });
                $scope.choiceShow = true;
            }else if($scope.nodeType == "variable"){
                $scope.choiceType = "变量类型";

                $scope.choiceResult.push({"variable":editData.node_cont});
                vm.choiceNode.push(editData.node_cont);
                $scope.choiceShow = true;
            }
            vm.from = "manual";
            $scope.scriptType = editData.scripts_type;
            if ($scope.scriptType == "shell"){
                $timeout(function () {
                    vm.editorSh(editData.scripts_cont, false);
                }, 1000);

            }else if($scope.scriptType == "python"){
                $timeout(function () {
                    vm.editorPy(editData.scripts_cont, false);
                }, 1000);
            }else if($scope.scriptType == "perl"){
                $timeout(function () {
                    vm.editorPerl(editData.scripts_cont, false);
                }, 1000);
            }else if($scope.scriptType == "php"){
                $timeout(function () {
                    vm.editorPhp(editData.scripts_cont, false);
                }, 1000);
            }else if($scope.scriptType == "buildin"){
                $timeout(function () {
                    vm.editorBuildin(editData.scripts_cont, false);
                }, 1000);
            }else if($scope.scriptType == "auto"){
                $timeout(function () {
                    vm.editorAuto(editData.scripts_cont, false);
                }, 1000);
            }else if($scope.scriptType == "cite"){
                vm.from = "local";

                $http.get('/api/job/scripts/' + vm.treeid+"/"+editData.scripts_cont).then(
                    function successCallback (response) {
                        if (response.data.stat){
                            var localscript = response.data.data;
                            $scope.scriptType = localscript.type;
                            $scope.localId = localscript.id;
                            $timeout(function () {
                                var typefunc = vm.scriptTypeEditor[localscript.type];
                                typefunc(localscript.cont, true);
                                $scope.scriptUnclick = true;
                            }, 1000);
                        }else {
                        }
                    },
                    function errorCallback () {
                    }
                );

            }
            $scope.s_argv = editData.scripts_argv;
            $scope.s_timeout = parseInt(editData.timeout);
            $scope.pause = editData.pause;

            vm.postdata = { deployenv: editData.deployenv, action: editData.action, batches: editData.batches };
        }
        if (vm.scriptid){
            $http.get('/api/job/scripts/' + vm.treeid + "/" + vm.scriptid).success(function(data){

                var scriptDict = data.data;
                vm.s_name = scriptDict.name;
                vm.s_cont = scriptDict.cont;
                $scope.scriptType = scriptDict.type;
                $scope.unClick = "true";
                vm.from = "local";
                if (scriptDict.type == "shell"){
                    vm.editorSh(vm.s_cont, true);
                }else if (scriptDict.type == "python"){
                    vm.editorPy(vm.s_cont, true);
                }else if (scriptDict.type == "perl"){
                    vm.editorPerl(vm.s_cont, true);
                }else if (scriptDict.type == "php"){
                    vm.editorPhp(vm.s_cont, true);
                }else if (scriptDict.type == "buildin"){
                    vm.editorBuildin(vm.s_cont, true);
                }else if (scriptDict.type == "auto"){
                    vm.editorAuto(vm.s_cont, true);
                }
                // editor.setReadOnly(false);
                // $("#editor").find("textarea").attr('readonly', 'readonly')
            });

        }else {
            vm.getAllScript();

        }
        vm.getProUser();

        vm.reloadticket = function(ticketid){
            $http.get('/api/ci/ticket?ticketid=' + ticketid ).success(function(data){
                if( data.stat)
                {
                    vm.ticketinfo = [];
                    angular.forEach(data.data, function (data, index) {
                        if( data.type === 'KubeConfig' || data.type === 'JobBuildin' )
                        {
                            vm.ticketinfo.push(data)
                        }
                    });
                    vm.ticketinfo.unshift({ id: '0', name: 'null' })
                }
                else
                {
                    toastr.error( "加载凭据列表失败:" + data.info )
                }
            });
        };

        if( editData )
        {
            var reg1 = new RegExp(/^[0-9]+$/);
            if (reg1.test(editData.user)) {
                vm.reloadticket( editData.user );
            }
        }
        else
        {
            vm.reloadticket( 0 );
        }

        $timeout(vm.editorSh, 500,true,"", false);

}})();
