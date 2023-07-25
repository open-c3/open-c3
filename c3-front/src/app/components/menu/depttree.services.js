(function () {

  'use strict';
  angular
    .module('openc3')
    .factory('deptTreeService', deptTreeService);

  function deptTreeService ($http, $state) {

    var vm = {};
    var setting = {
      view: {
        dblClickExpand: false,
        showTitle: false
      }
    };

    vm.sync = $http.get('/api/connector/connectorx/depttree').success(function (nodes) {
      var treedata = [ { id: 'root', name: 'ROOT', children: nodes.data } ];
      $.fn.zTree.init(angular.element('#departmentTree'), setting, treedata);
      vm.zdeptTree = $.fn.zTree.getZTreeObj('departmentTree');
      if (vm.zTree) {
        var treeNode = vm.zdeptTree.getNodeByParam('id', $state.params.treeid);
        var proName = $state.current.name;
        if (proName.indexOf('home.global') == 0) {
          return
        }
        if (treeNode == null) {
          return;
        }
      }
      return vm.zdeptTree;
    });

    vm.selectname = function () {
      var treeNode = vm.zdeptTree.getNodesByParam('id', $state.params.treeid);
      var currentNode = treeNode[treeNode.length - 1];
      var nodesStr = currentNode;
      while (currentNode.level != 0) {
        currentNode = currentNode.getParentNode();
        nodesStr = currentNode
      }
      return nodesStr;
    };

    return vm;
  }

})();
