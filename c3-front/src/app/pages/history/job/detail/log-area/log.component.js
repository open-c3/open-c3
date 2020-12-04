(function() {
    'use strict';

    angular
        .module('openc3')
        .component( 'jobTaskLogArea', {
            templateUrl: 'app/pages/history/job/detail/log-area/log.html',
            controller: taskLogController,
            bindings: { taskuuid: '=', jobaddr: '='}
        });

    function taskLogController($websocket, $location, $injector) {
        var vm = this;
        vm.height = vm.height || '200';
        var toastr = toastr || $injector.get('toastr');

        var urlMySocket = "ws://" + window.location.host + "/api/job/slave/"+vm.jobaddr+"/ws?uuid="+vm.taskuuid;

        vm.ws = $websocket(urlMySocket);
        vm.ws.onOpen(function (){
            console.log("opening ws");
        });
        vm.ws.onMessage(function (message) {
            setMessageInnerHTML(message.data)
        });
        vm.ws.onError(function (message) {
            toastr.error('打开日志失败')
        });
        vm.ws.onClose(function (message) {
        });
        function setMessageInnerHTML(innerHTML) {
            document.getElementById('messagejobtask').innerHTML += innerHTML + '<br/>';
        }
    }
})();
