(function () {
  'use strict';
  angular
      .module('openc3')
      .controller('SelectServiceTreeController', SelectServiceTreeController);

  function SelectServiceTreeController( $state, $http, $uibModalInstance, $scope, treeService, treeid, cloneNodeData) {

      var vm = this;
      vm.nodeStr = ''
      vm.treeObj = {};
      vm.toothertree = 0;
      vm.cloneNodeData = cloneNodeData? cloneNodeData : {cloneNodeId: treeid, cloneNodeName: ''}
      vm.zTree = '';
      var setting = {
        view: {
          dblClickExpand: false,
          showTitle: false
        }
      };
      treeService.sync.then(function () { 
        vm.nodeStr = treeService.selectname() || '';
      });

      vm.sync = $http.get('/api/connector/connectorx/usertree').success(function (nodes) {
        vm.treeObj = vm.findNodeById(nodes.data, vm.treeid)
        $.fn.zTree.init(angular.element('#openc3treecopy'), setting, nodes.data);
        vm.zTree = $.fn.zTree.getZTreeObj('openc3treecopy');
        if (vm.zTree) {
          var treeNode = vm.zTree.getNodeByParam('id', $state.params.treeid);
          var proName = $state.current.name;
          if (proName.indexOf('home.global') == 0) {
            return
          }
          if (treeNode == null) {
            return;
          }
        }
        return vm.zTree;
      });
  
      vm.sync.then(function () {
        vm.zTree = $.fn.zTree.getZTreeObj('openc3treecopy');
        vm.focusCurrent();
        vm.zTree.setting.callback.onClick = function (event, treeId, treeNode) {
          if (treeNode.hasOwnProperty('id')) {
            if (treeNode.id != 0) {
              var nodesStr = treeNode.name;
              const targetTreeId = treeNode.id
              while (treeNode.level != 0) {
                treeNode = treeNode.getParentNode();
                nodesStr = `${treeNode.name}.${nodesStr}`;
              }
              $scope.$apply(function () {
                vm.cloneNodeData = {
                  cloneNodeId: targetTreeId,
                  cloneNodeName: nodesStr
                }
              });
  
            } else {
              toastr.error("没有节点权限");
            }
          } else {
            toastr.error("没有节点权限");
          }
        }
      });
  
      vm.focusCurrent = function () {
        var cNode = vm.zTree.getNodeByParam('id', vm.cloneNodeData.cloneNodeId || $state.params.treeid);
        vm.zTree.selectNode(cNode);
        vm.zTree.expandNode(cNode);
      };
  
      vm.findNodeById = function (tree, id) {
        if (!tree || tree.length === 0) {
          return null;
        }
        for (let i = 0; i < tree.length; i++) {
          const node = tree[i];
          if (String(node.id) === String(id)) {
            return node;
          }
          if (node.children && node.children.length > 0) {
            const child = vm.findNodeById(node.children, id);
            if (child) {
              return child;
            }
          }
        }
  
        return null;
      };

      vm.cancel = function(){ $uibModalInstance.dismiss()};

      vm.confirm = function () {
        $uibModalInstance.close(vm.cloneNodeData);
      };
  }
})();

