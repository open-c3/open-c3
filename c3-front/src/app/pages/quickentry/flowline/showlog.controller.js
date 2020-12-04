(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CiShowLogController', CiShowLogController);

    function CiShowLogController($uibModalInstance, $http, $state, nodeStr, ngTableParams, reloadhome, versionuuid, slave, $websocket, $injector ) {

        var vm = this;
        vm.nodeStr = nodeStr;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };
        var toastr = toastr || $injector.get('toastr');

        vm.treeid = $state.params.treeid;

        vm.openws = function()
        {
            var hosturl = window.location.host;
            vm.siteaddr = window.location.host;

            var urlMySocket = "ws://" + vm.siteaddr + "/api/ci/slave/"+ slave +"/ws?uuid="+ versionuuid;
 
             vm.ws = $websocket(urlMySocket);

             vm.logDetail = '';
             vm.ws.onOpen(function (){
                console.log("opening ws");
             });

             vm.ws.onMessage(function (message) {
                 if(  message.data == 'wsresetws' )
                 {
                     vm.logDetail = '';
                 }
                 else
                 {
                     vm.logDetail = vm.logDetail + message.data
                 }

             });

             vm.ws.onError(function (message) {
                 toastr.error('打开日志失败')
             });

        }

        vm.openws();
 
     }
})();
