(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('AgentAgentController', AgentAgentController);

    function AgentAgentController($uibModalInstance, $http, $uibModal, $state, nodeStr, regionid, regionname, ngTableParams, reloadhome) {

        var vm = this;
        vm.nodeStr = nodeStr;
        vm.regionid = regionid;
        vm.regionname = regionname;

        vm.reloadhome = reloadhome
        vm.cancel = function(){ $uibModalInstance.dismiss(); vm.reloadhome();};

        vm.siteaddr = window.location.host;
        vm.treeid = $state.params.treeid;

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/agent/' + vm.treeid+'/'+regionid).success(function(data){
                vm.list = data.data;
                vm.agentlistTable = new ngTableParams({count:500}, {counts:[],data:vm.list});
                vm.loadover = true;
            });

        };

        vm.reload();

        vm.install = { username: 'root' };
        vm.showAgent = function( b ){
            vm.showAgentBool = b;
        }
 
       vm.deleteAgent = function(id) {
          swal({
            title: "删除网段",
            text: "删除网段",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/agent/' + vm.treeid+'/'+id ).success(function(data){
                if(data.stat == true) { swal({ title: "删除成功!", type:'success' }); vm.install.ip='';} else { swal({ title: "删除失败!", text: data.info, type:'error' });}
                vm.reload();
            });
          });
        }

        vm.installAgent = function( installtype ) {
          swal({
            title: "确认操作",
            text: "提交结束后请到安装历史中查看日志",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            vm.install.type = installtype + '_' + 'agent';
            $http.post('/api/agent/install/' + vm.treeid +'/' + regionid, vm.install ).success(function(data){
                vm.install = { username: 'root' };
                if(data.stat == true) { swal({ title: "提交成功!", type:'success' }); vm.install.ip='';} else { swal({ title: "提交失败!", text: data.info, type:'error' }); }
            });
          });
        }

        vm.addSubNet = function() {
            $http.post('/api/agent/agent/' + vm.treeid +'/' + regionid + '/subnet', { subnet: vm.install.ip } ).success(function(data){
                if(data.stat == false) { swal({ title: "添加失败!", text: data.info, type:'error' }); }
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
