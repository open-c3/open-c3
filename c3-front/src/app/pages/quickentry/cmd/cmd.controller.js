(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('QuickController', QuickController);

    function QuickController($scope,$filter, $state, $http,$window,$uibModal, $timeout,treeService,resoureceService, scriptId, $injector) {

        var vm = this;
        $scope.dataready = true;
        var toastr = toastr || $injector.get('toastr');
        vm.choiceNode = [];
        vm.scriptid = scriptId.getter();
        scriptId.del();
        vm.treeid = $state.params.treeid;
        vm.scriptHide = true;
        $scope.choiceShow = false;
        $scope.s_argv = "";
        $scope.s_timeout = '60';
        vm.s_name = "快速执行脚本-" + $filter('date')(new Date, "yyyyMMddHHmmss") + $filter('date')(new Date, "sss");

        vm.postdata = { deployenv: 'always', action: 'always', batches: 'always' };

        treeService.sync.then(function(){      // when the tree was success.
            vm.nodeStr = treeService.selectname();  // get tree name

        });

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
            "auto": vm.editorAuto
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
            vm.scriptHide = true;
            vm.click = "manual";
        };
        vm.scriptManual();
        vm.from = 'manual';
        vm.scriptClone =function () {
            if (vm.click != "clone"){
                vm.scriptHide = false;
                $scope.selectedScript = '';
                ace.edit("editor").setValue('');
                ace.edit("editor").setReadOnly(false);
                $scope.scriptType = "";
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

        vm.run = function (scriptForm) {
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

            if (!vm.from){
                swal({
                    title:"脚本来源不能为空",
                    type:'error'
                });
                return
            }else if (vm.choiceNode.length == 0){
                swal({
                    title:"所选机器不能为空",
                    type:'error'
                });
                return
            }else if(!$scope.scriptType){
                swal({
                    title:"脚本类型不能为空",
                    type:'error'
                });
                return
            }else if(!cont){
                swal({
                    title:"脚本内容为空",
                    type:'error'
                });
                return
            }else if(!$scope.selectedUser){
                swal({
                    title:"用户不能为空",
                    type:'error'
                });
                return
            }

            cont = cont.replace(/\r\n/g, "\n");
            var post_data ={
                'name': vm.s_name,
                'user': $scope.selectedUser,
                'node_type':$scope.nodeType,
                'node_cont':vm.choiceNode.join(","),
                'scripts_type':$scope.scriptType,
                'scripts_cont': cont,
                'scripts_argv': $scope.s_argv,
                'timeout': parseInt($scope.s_timeout),
                'deployenv' : vm.postdata.deployenv,
                'action' : vm.postdata.action,
                'batches' : vm.postdata.batches
            };
            resoureceService.work.runScript(vm.treeid, post_data, null)
                .then(function (repo) {
                    // success
                    scriptForm.$setPristine();
                    scriptForm.$setUntouched();

                    vm.s_name = "快速执行脚本-" + $filter('date')(new Date, "yyyyMMddHHmmss") + $filter('date')(new Date, "sss");
                    vm.from = '';
                    vm.click = '';
                    $scope.choiceResult = [];
                    $scope.selectedUser = '';
                    $scope.scriptType = '';
                    $scope.s_timeout = '60';
                    $scope.s_argv = '';
                    $scope.choiceShow = false;
                    ace.edit("editor").setValue('');
                    ace.edit("editor").setReadOnly(false);
                    vm.scriptManual();
                    vm.from = 'manual';
                    vm.getAllScript();
                    if (repo.stat){
                        vm.openDetail(repo.data);
                    }
                    else
                    {
                        toastr.error("提交执行失败:" + repo.info)
                    }

                },function (repo) {
                    toastr.error("提交执行失败:" + repo)
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
                    }
                    $scope.scriptType = data.data.type;
                }
            });
        };


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

        vm.reloadticket = function(){
            $http.get('/api/ci/ticket').success(function(data){
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

        vm.reloadticket();

}})();
