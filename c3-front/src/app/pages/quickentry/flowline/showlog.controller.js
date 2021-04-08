(function () {
    // 'use strict';
    angular
        .module('openc3')
        .controller('CiShowLogController', CiShowLogController);

    function CiShowLogController($uibModalInstance, $http, $state, nodeStr, ngTableParams, reloadhome, versionuuid, slave, $websocket, $injector, $scope, $sce, $timeout ) {

        var vm = this;
        vm.nodeStr = nodeStr;
        $scope.uCanTrust = function(string){
            return $sce.trustAsHtml(string);
        }
        vm.cancel = function(){ $uibModalInstance.dismiss(); };
        var toastr = toastr || $injector.get('toastr');
        vm.treeid = $state.params.treeid;

        vm.openws = function()
        {
            var ansi_up = new AnsiUp;
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
                    vm.logDetail = vm.logDetail + ansi_up.ansi_to_html(message.data)
                    $timeout(function () {
                        var dom = document.getElementById('logDetail')
                        dom.scrollTop = dom.scrollHeight
                    }, 0)
                 }
             });
             vm.ws.onError(function (message) {
                 toastr.error('打开日志失败')
             });

        }

        vm.openws();
 
     }
})();
