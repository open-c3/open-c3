(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CreateMonitorConfigRuleController', CreateMonitorConfigRuleController);

    function CreateMonitorConfigRuleController($http, $uibModal, $uibModalInstance, $scope, treeService, treeid, reload, postData, title) {

        var vm = this;
        vm.title = title
        vm.treeid = treeid;
        vm.nodeStr = '';
        vm.monitorOperate = title.includes('克隆');
        $scope.cloneNodeData = {cloneNodeId: null, cloneNodeName: ''}
        treeService.sync.then(function () { 
          vm.nodeStr = treeService.selectname() || '';
        });

        vm.postData = { 'severity': 'level2', 'model': 'bindtree' }
        if( postData.id )
        {
            vm.postData.id = postData.id
            vm.postData.alert = postData.alert
            vm.postData.expr = postData.expr
            vm.postData.for = postData.for
            vm.postData.severity = postData.severity
            vm.postData.summary = postData.summary
            vm.postData.description = postData.description
            vm.postData.value = postData.value
            vm.postData.model = postData.model
            vm.postData.metrics = postData.metrics
            vm.postData.method = postData.method
            vm.postData.threshold = postData.threshold
            vm.postData.bindtreesql = postData.bindtreesql
            vm.postData.job = postData.job
            vm.postData.subgroup = postData.subgroup

            vm.postData.nocall = postData.nocall
            vm.postData.nomesg = postData.nomesg
            vm.postData.nomail = postData.nomail

            vm.postData.serialcall = postData.serialcall

            vm.postData.vtreeid = postData.vtreeid
        }

        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.handleSelectTree = function () {
          const selectTreeModal = $uibModal.open({
            templateUrl: 'app/pages/quickentry/monitorconfig/create/servicetree.html',
            controller: 'SelectServiceTreeController',
            controllerAs: 'selectServicetree',
            backdrop: 'static',
            size: 'md',
            keyboard: false,
            bindToController: true,
            resolve: {
              treeid: function () { return vm.treeid },
              cloneNodeData: function () {
                return {
                  cloneNodeId: $scope.cloneNodeData.cloneNodeId,
                  cloneNodeName: $scope.cloneNodeData.cloneNodeName
                }
              }
            }
          });
    
          selectTreeModal.result.then(function (cloneNodeData) {
            $scope.cloneNodeData = cloneNodeData;
          });
        };

        vm.add = function(){
          const targetTreeId = $scope.cloneNodeData.cloneNodeId ? $scope.cloneNodeData.cloneNodeId : treeid
          if (vm.monitorOperate) delete vm.postData.id
            $http.post(`/api/agent/monitor/config/rule/${targetTreeId}`,  vm.postData ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else { swal({ title: "添加监控指标采集失败!", text: data.info, type:'error' }); }
            });
        };

        vm.getVirtualTreeList = function () {
            $http.get(`/api/connector/vtree/${treeid}`).success(function (data) {
              if (data.stat == true) {
                  vm.vtreeList = data.data;
              } else {
                  toastr.error("加载失败:" + data.info);
              }
            });
        };

         vm.getVirtualTreeList();

    }
})();

