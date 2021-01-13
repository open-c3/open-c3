(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('FavoritesController', FavoritesController);

    function FavoritesController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, $injector,genericService, $scope) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');
        vm.time2date = genericService.time2date
        vm.seftime = genericService.seftime

        $scope.panelcolor = { "success": "green", "fail": "red", "running": "#98b2bc", "decision": "#aaa", "ignore": "#aaa" }

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.openws = function()
        {
            var hosturl = window.location.host;
            vm.siteaddr = window.location.host;

            var urlMySocket = "ws://" + vm.siteaddr + "/api/ci/slave/"+ vm.project.slave +"/ws?uuid="+ vm.treeid;
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

        vm.versiondetail = function (groupid,id) {
            $state.go('home.quickentry.flowlinedetail', {treeid:groupid, projectid: id});
        };

        vm.treedetail = function (id) {
            $state.go('home.quickentry.flowline', {treeid: id});
        };

        vm.editconfig = function (id) {
            $uibModal.open({
                templateUrl: 'app/pages/config/config.html',
                controller: 'ConfigController',
                controllerAs: 'config',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    getGroup: function () {return vm.getGroupInfo},
                    projectid: function () {return id},
                    treeid: function () {return vm.treeid},
                    groupid: function () {},
                }
            });
        };

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/ci/group/favorites/' + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    var mtree = []
                    var htree = {}
                    angular.forEach(data.data, function (value, key) {
                        if( ! htree[value.groupid] )
                        {
                            htree[value.groupid] = 1
                            mtree.push(value.groupid)
                        }
                    });
                    if( mtree.length )
                    {
                        vm.getTaskInfo(mtree.join(","));
                    }

                    vm.activeRegionTable = new ngTableParams({count:20}, {counts:[],data:data.data.reverse()});
                    vm.loadover = true;
                } else { 
                    toastr.error( "加载版本失败:" + data.info )
                }
            });
        };

        vm.reload();

        vm.loadfindtags_at_onceover = true;
        vm.findtags_at_once = function(){
            vm.loadfindtags_at_onceover = false;
            $http.put('/api/ci/project/' + vm.treeid + '/findtags_at_once' ).success(function(data){
                if(data.stat == true) 
                {
                    vm.loadfindtags_at_onceover = true;
                } else { 
                    toastr.error( "触发寻找tag失败:" + data.info );
                }
            });
        };

        vm.showlog = function(versionuuid,slave){
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/showlog.html',
                controller: 'CiShowLogController',
                controllerAs: 'showlog', 
                backdrop: 'static', 
                size: 'lg', 
                keyboard: false,
                bindToController: true,
                resolve: {
                    nodeStr: function () { return vm.nodeStr },
                    reloadhome: function () { return vm.reload },
                    versionuuid: function () { return versionuuid },
                    slave: function () { return slave }
                }
            });
        };

        vm.deployDetail = function(treeid, uuid){
            $state.go('home.history.jobxdetail', {treeid:treeid, taskuuid:uuid, accesspage:true});
        };

        vm.addToFavorites = function (id, name) {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/flowline/addToFavorites.html',
                controller: 'AddToFavoritesController',
                controllerAs: 'addToFavorites',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    sourceid: function () { return id},
                    sourcename: function () { return name},
                    reload : function () { return vm.reload}
                }
            });
        };


        vm.delToFavorites = function(id) {
          swal({
            title: "取消收藏",
            text: "取消",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/ci/favorites/' + vm.treeid + '?ciid=' + id ).success(function(data){
                if( data.stat)
                {
                    vm.reload();
                }
                else
                {
                    toastr.error("取消收藏失败:" + data.info)
                }
            });
          });
        }

        vm.addFavorites = function () {
            $uibModal.open({
                templateUrl: 'app/pages/favorites/addFavorites.html',
                controller: 'AddFavoritesController',
                controllerAs: 'addfavorites',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () { return vm.treeid},
                    homereload : function () { return vm.reload}
                }
            });
        };


        vm.taskInfoTest = {}
        vm.taskInfoOnline = {}

        vm.taskInfoTestRunning = {}
        vm.taskInfoOnlineRunning = {}

        vm.getTaskInfo = function (treeId) {
            $http.get('/api/jobx/task/' + treeId + '?allowslavenull=1&name=_ci_' ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        angular.forEach(response.data.data, function (value, key) {

                        var projectid = vm.cprojectid( value.name );
                        var version = vm.cversion( value.variable );
                        var jobtype = vm.cjobtype( value.variable );
                        value.version = version

                        if( value.slave != '_null_' && jobtype == 'test' )
                        {
                            vm.taskInfoTest[projectid] = value
                            if( value.status == 'running' )
                            {
                                vm.taskInfoTestRunning[projectid] = 1
                            }
                        }

                        if( value.slave != '_null_' && jobtype == 'online' )
                        {
                            vm.taskInfoOnline[projectid] = value
                            if( value.status == 'running' )
                            {
                                vm.taskInfoOnlineRunning[projectid] = 1
                            }
                        }

                        });
                    }else {
                        toastr.error( "获取数据失败:" + response.data.info )
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取数据失败:" + response.status )
                });
        };

        vm.cprojectid = function(text) {
            var w = text.split("_");
            if(w[1] == 'ci' && w[0] == '' && w[3] == '' )
            {
                return w[2]
            }
            else
            {
                return ''
            }
        }

 
        vm.cversion = function(text) {
            var w = '';
            var re=/version:.*/;
            if (re.test(text)){
                var reStr = re.exec(text)[0];
                w = reStr.split(" ")[1]
                var xx = /'/;
                if( xx.test(w) )
                {
                    w = w.split("'")[1]
                }
            }
            return w
        }

        vm.cjobtype = function(text) {
            var w = '';
            var re=/_jobtype_:.*/;
            if (re.test(text)){
                var reStr = re.exec(text)[0];
                w = reStr.split(" ")[1]
                var xx = /'/;
                if( xx.test(w) )
                {
                    w = w.split("'")[1]
                }
            }
            return w
        }

        vm.deployType = function (uuid){
            uuid = uuid.slice(uuid.length - 1);
            if (64 < uuid.charCodeAt(0) && uuid.charCodeAt(0) < 91) {
                return '回滚'
            } else {
                return '发布'
            }
        };

    }
})();
