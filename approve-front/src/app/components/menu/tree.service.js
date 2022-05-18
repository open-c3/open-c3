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
