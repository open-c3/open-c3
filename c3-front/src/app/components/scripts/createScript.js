(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateScript', CreateScript);

    /** @ngInject */
    function CreateScript($uibModalInstance,$scope,$state,$http,$timeout, resoureceService, reloadindex, msg, edit) {

        var vm = this;
        $scope.dataready = true;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.treeid = $state.params.treeid;
        if (edit == "true"){
            $scope.editStatus = true;
        }
        vm.getAllScript = function () {
            vm.scriptHide = true;
            if (vm.treeid){
                $http.get('/api/job/scripts/' + vm.treeid).then(
                    function successCallback(response) {
                        vm.scriptHide = true;
                        if (response.data.stat){
                            $scope.dataready = true;
                            $scope.allScript = response.data.data;
                        }else {
                            $scope.dataready = false;
                            $scope.dataerror = "获取脚本信息失败："+response.data.info;
                        }
                    },
                    function errorCallback (response){
                        $scope.dataready = false;
                        $scope.dataerror =  "获取脚本信息失败: " + response.status
                    });
            }
        };
        vm.save = function(){
            var scriptMsg = vm.inputValue();
            if (edit == "false"){
                if (!vm.from){
                    alert("脚本来源必选！");
                    return
                }
                if(!scriptMsg.type){
                    alert("脚本类型必选");
                    return
                }else if (!scriptMsg.cont){
                    alert("脚本内容不能为空");
                    return
                }
                resoureceService.script.create(vm.treeid,scriptMsg, null).finally(function(){
                    vm.cancel();
                    reloadindex(vm.treeid);

                });
            }else if (edit == "true"){
                vm.scriptid = msg.id;
                resoureceService.script.change([vm.treeid, vm.scriptid],scriptMsg, null).finally(function(){
                    vm.cancel();
                    reloadindex(vm.treeid);
                });
            }

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
        };
        vm.editorPy = function (data, re) {
            vm.pyEditor = ace.edit("editor");
            var pyeditor = vm.pyEditor;
            pyeditor.setTheme("ace/theme/dracula");
            pyeditor.session.setMode("ace/mode/python");
            document.getElementById('editor').style.fontSize='14px';
            pyeditor.setShowPrintMargin(false);
            pyeditor.setHighlightActiveLine(false);
            if (data){
                pyeditor.setValue(data);
            }
            if (re){
                pyeditor.setReadOnly(true)
            }
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
        };
 
        vm.editorAuto = function (data, re) {
            vm.autoeditor = ace.edit("editor");
            var autoeditor  = vm.autoeditor;
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
        };
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
                // if ($scope.scriptType){
                ace.edit("editor").setValue('');
                ace.edit("editor").setReadOnly(false);
                $scope.unClick = false;
                // }
            }
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
            }
            vm.click = "clone";

        };


        vm.inputValue = function() {

            var scriptMsg = {'type':'', 'cont':''};

            if ($scope.scriptType == 'shell'){
                scriptMsg['type'] = 'shell';
                scriptMsg['cont'] = vm.shEditor.getValue();
            }else if($scope.scriptType == 'python'){
                scriptMsg['type'] = 'python';
                scriptMsg['cont'] = vm.pyEditor.getValue();
            }else if($scope.scriptType == 'perl'){
                scriptMsg['type'] = 'perl';
                scriptMsg['cont'] = vm.perlEditor.getValue();
            }else if($scope.scriptType == 'php'){
                scriptMsg['type'] = 'php';
                scriptMsg['cont'] = vm.phpEditor.getValue();
            }else if($scope.scriptType == 'buildin'){
                scriptMsg['type'] = 'buildin';
                scriptMsg['cont'] = vm.buildinEditor.getValue();
            }else if($scope.scriptType == 'auto'){
                scriptMsg['type'] = 'auto';
                scriptMsg['cont'] = vm.autoeditor.getValue();
            }
            scriptMsg['name'] = $scope.scriptName;
            return scriptMsg
        };
        vm.inputScript = function () {
            // get script by id and set selected id.
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
                    }
                    $scope.scriptType = data.data.type;
                }
            });
        };

        vm.getAllScript();

        if (msg){
            $scope.scriptName = msg.name;
            $scope.scriptType = msg.type;
            if(msg.type=="shell"){
                $timeout(vm.editorSh, 500,true,msg.cont, false);
            }else if (msg.type=="python"){
                $timeout(vm.editorPy, 500,true,msg.cont, false);
            }else if (msg.type=="perl"){
                $timeout(vm.editorPerl, 500,true,msg.cont, false);
            }else if (msg.type=="php"){
                $timeout(vm.editorPhp, 500,true,msg.cont, false);
            }else if (msg.type=="buildin"){
                $timeout(vm.editorBuildin, 500,true,msg.cont, false);
            }else if (msg.type=="auto"){
                $timeout(vm.editorAuto, 500,true,msg.cont, false);
            }
            vm.from = "local";
            $scope.unClick = true;

        }
        else {
            $scope.scriptType = "shell";
            $timeout(vm.editorSh, 500,true,"", false);
        }

    }
})();

