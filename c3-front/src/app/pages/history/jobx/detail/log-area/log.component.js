(function() {
    'use strict';

    angular
        .module('openc3')
        .component( 'jobxTaskLogArea', {
            templateUrl: 'app/pages/history/jobx/detail/log-area/log.html',
            controller: taskLogController,
            bindings: { taskuuid: '=', jobxaddr: '='}
        });

    function taskLogController($websocket, $location, $injector) {
        var vm = this;
        vm.height = vm.height || '200';
        var toastr = toastr || $injector.get('toastr');

        var urlMySocket = "ws://" + window.location.host + "/api/jobx/slave/"+vm.jobxaddr+"/ws?uuid="+vm.taskuuid;

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
            document.getElementById('messagejobxtask').innerHTML += innerHTML + '<br/>';
        }
    }
})();
