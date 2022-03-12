(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateMonitorOncallListController', CreateMonitorOncallListController);

    function CreateMonitorOncallListController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, postData, $injector) {

        var vm = this;
        var toastr = toastr || $injector.get('toastr');

        vm.postData = postData

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

        vm.reload = function( )
        {
            vm.loadover = false;
            $http.get('/api/agent/monitor/config/oncall/list/' + postData.name ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.loadover = true;
                    vm.editorSh( data.data, 1 );
                } else { 
                    toastr.error( "加载数据失败:" + data.info )
                }
            });
 
       };

       vm.reload();

       vm.cancel = function(){ $uibModalInstance.dismiss()};
    }
})();

