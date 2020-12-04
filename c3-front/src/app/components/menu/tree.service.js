(function() {

    'use strict';
    angular
        .module('openc3')
        .factory('treeService', treeService);

    function treeService($http, $state){

        var vm = {};
        var setting = {
            view: {
                dblClickExpand: false,
                showTitle:false
            }
        };

        vm.sync = $http.get('/api/connector/connectorx/usertree').success(function(nodes) {
            $.fn.zTree.init(angular.element('#openc3tree'), setting, nodes.data);
            vm.zTree = $.fn.zTree.getZTreeObj('openc3tree');
            if (vm.zTree){
                var treeNode = vm.zTree.getNodeByParam('id', $state.params.treeid);
                var proName = $state.current.name;
                if (proName.indexOf('home.global') == 0 ){
                    return
                }
                if(treeNode == null){
                    // $state.go('home.e401');
                    return;
                }

                // var demo = vm.zTree.getNodeByParam("id", demoId, 0);
                // vm.zTree.addNodes(null,0, demo);
            }

            return vm.zTree;
        });

        vm.selectname = function(){
            var treeNode = vm.zTree.getNodesByParam('id', $state.params.treeid);
            var currentNode = treeNode[treeNode.length-1];
            var nodesStr = currentNode.name;
            while(currentNode.level != 0){
                currentNode = currentNode.getParentNode();
                nodesStr = currentNode.name + '.' + nodesStr;
            }
            return nodesStr;
        };

        return vm;
    }

})();
