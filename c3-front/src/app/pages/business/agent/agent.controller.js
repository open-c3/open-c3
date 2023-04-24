(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AgentController', AgentController);

    function AgentController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService) {

        var vm = this;
        vm.treeid = $state.params.treeid;

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });
        vm.siteaddr = window.location.protocol + '//' + window.location.host;
        vm.checkoldstatus=false;
        vm.checknewstatus=false;
        vm.reloadcheck = function(){
            $http.get('/api/agent/check/' + vm.treeid ).success(function(data){
                vm.checkstatusloadover = true;
                vm.checkstatusdata = data.data;
                if(  data.data.status == 'off' )
                {
                    vm.checkoldstatus=false;
                    vm.checknewstatus=false;
                }
                else
                {
                    vm.checkoldstatus=true;
                    vm.checknewstatus=true;
                }
            });
        };

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/region/' + vm.treeid+'/active').success(function(data){
                vm.activeRegionTable = new ngTableParams({count:20}, {counts:[],data:data.data});
                vm.loadover = true;
            });
            vm.reloadcheck();
        };

        vm.reload();


        vm.savecheckstatus = function(){
          swal({
            title: "保存新状态",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            vm.checkstatus = 'off';
            if( vm.checknewstatus == true)
            {
                vm.checkstatus = 'on';
            }
            $http.post('/api/agent/check/' + vm.treeid, { status: vm.checkstatus} ).success(function(data){
				if(data.stat == true) 
                { 
                    swal({ title: "修改成功!", type:'success' }); 
                    vm.checkoldstatus= vm.checknewstatus;
                } else { 
                    swal({ title: "修改失败!", text: data.info, type:'error' });
                }
            })

          })
        }

        vm.addregion = function(t){
            $uibModal.open({
                templateUrl: 'app/pages/business/agent/detail/region.html',
                controller: 'AgentRegionController',
                controllerAs: 'region', 
                backdrop: 'static', 
                size: 'lg', 
                keyboard: false,
                bindToController: true,
                resolve: {
                    nodeStr: function () { return vm.nodeStr },
                    reloadhome: function () { return vm.reload },
                    reloadhome: function () { return vm.reload }
                }
            });
        };

        vm.addproxy = function(regionid,regionname){
            $uibModal.open({
                templateUrl: 'app/pages/business/agent/detail/proxy.html',
                controller: 'AgentProxyController',
                controllerAs: 'proxy', 
                backdrop: 'static', 
                size: 'lg', 
                keyboard: false,
                bindToController: true,
                resolve: {
                    nodeStr: function () { return vm.nodeStr },
                    regionid: function () { return regionid },
                    regionname: function () { return regionname },
                    reloadhome: function () { return vm.reload }
                }
            });
        };

        vm.addagent = function(regionid,regionname){
            $uibModal.open({
                templateUrl: 'app/pages/business/agent/detail/agent.html',
                controller: 'AgentAgentController',
                controllerAs: 'agent', 
                backdrop: 'static', 
                size: 'lg', 
                keyboard: false,
                bindToController: true,
                resolve: {
                    nodeStr: function () { return vm.nodeStr },
                    regionid: function () { return regionid },
                    regionname: function () { return regionname },
                    reloadhome: function () { return vm.reload }
                }
            });
        };

        vm.showLog = function(slave,uuid,status){
            $uibModal.open({
                templateUrl: 'app/pages/installLog/detail/log.html',
                controller: 'InstallLogLogController',
                controllerAs: 'log',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    nodeStr: function () { return vm.nodeStr },
                    uuid: function () { return uuid },
                    slave: function () { return slave },
                    status: function () { return status }
                }
            });
        };
    }
})();
