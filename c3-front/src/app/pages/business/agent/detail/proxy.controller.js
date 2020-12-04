(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('AgentProxyController', AgentProxyController);

    /** @ngInject */
    function AgentProxyController($uibModalInstance, $http, $uibModal, $state, nodeStr, regionid, regionname,  ngTableParams, reloadhome ) {

        var vm = this;
        vm.nodeStr = nodeStr;
        vm.regionid = regionid;
        vm.regionname = regionname;
        vm.reloadhome = reloadhome

        vm.cancel = function(){ $uibModalInstance.dismiss(); vm.reloadhome(); };

        vm.siteaddr = window.location.host;
        vm.treeid = $state.params.treeid;

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/proxy/' + vm.treeid+'/'+regionid).success(function(data){
                vm.list = data.data;
                vm.proxylistTable = new ngTableParams({count:500}, {counts:[],data:vm.list});
                vm.loadover = true;
            });
        };

        vm.reload();

        vm.install = { username: 'root'};
        vm.showProxy = function( b ){
            vm.showProxyBool = b;
        }
 
        vm.deleteProxy = function(id) {
          swal({
            title: "删除代理",
            text: "代理被删除后，如果该区域下没有可用的代理，区域下的机器调用将会失败",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/proxy/' + vm.treeid+'/'+id ).success(function(data){
                if(data.stat == false) { swal({ title: "删除失败!", text: data.info, type:'error' });}
                vm.reload();
            });
         });
        }
       vm.installProxy = function( installtype ) {
            $http.post('/api/agent/proxy/' + vm.treeid +'/' + regionid, vm.install ).success(function(data){
                if(data.stat) {
                    swal({ title: "提交成功!", type:'success' });
                    vm.install.ip = ''
                } else { 
                    swal({ title: "提交失败!", text: data.info, type:'error' });
                }
                vm.reload();
            });
        }

        vm.updateselectip = function(ips) {
            vm.install.ip = ips;
        }

        vm.selectIpFromTree = function() {
            $uibModal.open({
                templateUrl: 'app/pages/business/agent/detail/host.html',
                controller: 'AgentHostController',
                controllerAs: 'host', 
                backdrop: 'static', 
                size: 'lg', 
                keyboard: false,
                bindToController: true,
                resolve: {
                    nodeStr: function () { return vm.nodeStr },
                    regionid: function () { return regionid },
                    selectip: function() { return vm.updateselectip }
                }
            });
        }
    }
})();
