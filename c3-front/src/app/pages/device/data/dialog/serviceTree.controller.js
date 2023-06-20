(function () {
  'use strict';

  angular
    .module('openc3')
    .controller('ServiceTreeController', ServiceTreeController)
    .filter('cut30', function () {
      return function (text) {
        if (text.length > 33) {
          return "..." + text.substr(text.length - 30)
        }
        return text;

      }
    });

  function ServiceTreeController ($uibModalInstance, $window, $state, $http, $scope, treeService, type, treeid, selectResDetail) {

    var vm = this;
    vm.treeid = treeid;
    vm.type = type;
    vm.selectResDetail = selectResDetail;
  
    treeService.sync.then(function () { 
      vm.nodeStr = treeService.selectname() || '';
    });

    vm.treeObj = {};
    vm.toothertree = 0;
    vm.cloneNodeId = treeid;
    vm.cloneNodeName = '';
    vm.zTree = '';
    angular.element('.scroller').css('height', $window.innerHeight - 95);
    angular.element($window).bind('resize', function () {
      angular.element('.scroller').css('height', $window.innerHeight - 95);
    });
    var setting = {
      view: {
        dblClickExpand: false,
        showTitle: false
      }
    };

    vm.cancel = function () { $uibModalInstance.dismiss() };

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
            while (treeNode.level != 0) {
              treeNode = treeNode.getParentNode();
              nodesStr = `${treeNode.name}.${nodesStr}`;
            }
            $scope.$apply(function () {
              vm.cloneNodeId = treeNode.id;
              vm.cloneNodeName = nodesStr;
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
      var cNode = vm.zTree.getNodeByParam('id', $state.params.treeid);
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

    vm.confirm = function () {
      swal({
        title: `确定要${vm.type === 'move'? '移动': '复制'}到目标服务树吗？`,
        type: "warning",
        showCancelButton: true,
        confirmButtonColor: "#DD6B55",
        cancelButtonText: "取消",
        confirmButtonText: "确定",
        closeOnConfirm: true
      }, function () {
        angular.forEach(vm.selectResDetail, function (item) {
          const targetTree = vm.type === 'move'? `/${vm.nodeStr}/${vm.cloneNodeName}`: `/${vm.cloneNodeName}`
          $http.post(`/api/agent/device/tree/${vm.type}/${item.type}/${item.subtype}/${item.uuid}${targetTree}`).success(function (data) {
            if (data.stat == true) {
              toastr.success("操作完成");
              vm.cancel();
            } else {
              toastr.error("操作失败:" + data.info)
            }
          });
        })
      });
    }
  }
})();
