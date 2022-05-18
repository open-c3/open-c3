(function () {
    'use strict';
    angular
        .module('openc3')
        .directive('nodestr', nodeStr);

    function nodeStr() {
        var directive = {

            restrict: 'E',
            templateUrl: 'app/components/nodestr/nodeStr.html',
            scope: {},
            controller: nodeStr,
            controllerAs: 'node'
        };

        return directive;

        function nodeStr(treeService) {

            var vm = this;

            treeService.sync.then(function(){      // when the tree was success.

                vm.nodeStr = treeService.selectname();  // get tree name
            });
        }
    }

})();

