(function() {
    'use strict';

    angular
        .module('openc3')
        .component('jobSubtaskLogArea', {
            templateUrl: 'app/pages/history/job/detail/sublog-area/log.html',
            controller: LogController,
            bindings: { jobuuid: '=', jobaddr: '=', loguuid:'='}
        });

    function LogController($websocket, $location, $injector, $scope, $interval) {
        var vm = this;
        vm.height = vm.height || '200';
        var toastr = toastr || $injector.get('toastr');

        var wsH = "ws://"
        if ( window.location.protocol == 'https:' )
        {
            wsH = "wss://"
        }
        var urlMySocket = wsH + window.location.host + "/api/job/slave/"+vm.jobaddr+"/ws?uuid="+vm.loguuid;

        vm.ws = $websocket(urlMySocket);
        vm.ws.onOpen(function (){
            console.log("open ws");
        });
        vm.ws.onMessage(function (message) {
            setMessageInnerHTML(message.data)
        });
        vm.ws.onError(function (message) {
            toastr.error('打开日志失败')
        });
        vm.ws.onClose(function (message) {
            console.log("close ws");
        });
        function setMessageInnerHTML(innerHTML) {
            document.getElementById('messagejobsubtask').innerHTML += innerHTML + '<br/>';
        }


        var rc = 0;
        var reRun = $interval(function () {
            if (vm.taskuuid){ vm.reload(); }
            rc = rc + 1;
            if( rc < 300 )
            {
                vm.ws.send("H")
            }
 
        }, 6000);

        $scope.$on('$destroy', function(){
            $interval.cancel(reRun);
            vm.ws.onClose();
        });
    }
})();
