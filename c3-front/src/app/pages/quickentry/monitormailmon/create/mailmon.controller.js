(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateMonitorMailmonMailmonController', CreateMonitorMailmonMailmonController);

    function CreateMonitorMailmonMailmonController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, postData, title) {

        var vm = this;
        vm.title = title
        vm.postData = {}

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

vm.demo = `
---
POP3:
  USER: foo@xx.com
  PASSWORD: abc123
  HOST: pop.exmail.qq.com

to: '@ops'
`;

        if( postData.id )
        {
            vm.postData.id = postData.id
            vm.postData.name = postData.name
            vm.postData.description = postData.description

            $http.get('/api/agent/monitor/config/mailmon/' + postData.id ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.postData = data.data
                    vm.editorSh( data.data.config );
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载信息失败:" + data.info )
                }
            });
 
        }
        else
        {
            setTimeout(function () {
                vm.editorSh( vm.demo );
             }, 500);
        }

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.add = function(){
            vm.postData.config = vm.shEditor.getValue();
            $http.post('/api/agent/monitor/config/mailmon', vm.postData ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "操作失败!", text: data.info, type:'error' }); }
            });
        };
    }
})();

