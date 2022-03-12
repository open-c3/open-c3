(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateMonitorOncallCalController', CreateMonitorOncallCalController);

    function CreateMonitorOncallCalController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, treeid, reload, postData, $injector) {

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
            $http.get('/api/agent/monitor/config/oncall/' + vm.postData.id ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.users = data.data.user
                } else { 
                    toastr.error( "加载值班组信息失败:" + data.info )
                }
            });
         };

         vm.reload();

         vm.userch = function( )
         {
             vm.loadCal( vm.user );
         };

         vm.loadCal = function( user )
         {
              vm.loadover = false;
              $http.get('/api/agent/monitor/config/oncall/cal/' + postData.name + '?user=' + user  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.loadover = true;
                    vm.editorSh( data.data, 1 );
                } else { 
                    toastr.error( "加载日历失败:" + data.info )
                }
            });
 
        };

        vm.loadCal();

        vm.cancel = function(){ $uibModalInstance.dismiss()};

    }
})();

