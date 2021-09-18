(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('FindTagController', FindTagController);

    function FindTagController($uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, $injector ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.projectid = $state.params.projectid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss()};
        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.openws = function()
        {
            var hosturl = window.location.host;
            vm.siteaddr = window.location.host;

            var wsH = "ws://"
            if ( window.location.protocol == 'https:' )
            {
                wsH = "wss://"
            }
            var urlMySocket = wsH + vm.siteaddr + "/api/ci/slave/"+ vm.project.slave +"/ws?uuid="+ vm.projectid;
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

        vm.reloadprojectinfo = function(){
            $http.get('/api/ci/project/' + vm.treeid + '/' + vm.projectid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.project = data.data;
                    if (vm.project.slave){
                        vm.openws();
                    }
                } else {
                    toastr.error( "加载项目信息失败:" + data.info )
                }
            });
        };

        vm.reloadprojectinfo();

        vm.loadfindtags_at_onceover = true;
        vm.findtags_at_once = function(){
            vm.loadfindtags_at_onceover = false;
            $http.put('/api/ci/project/' + vm.treeid + '/' + vm.projectid + '/findtags_at_once' ).success(function(data){
                if(data.stat == true) 
                {
                    vm.loadfindtags_at_onceover = true;
                } else { 
                    toastr.error( "触发寻找tag失败:" + data.info )
                }
            });
        };

    }
})();
