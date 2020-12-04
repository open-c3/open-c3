(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('QuickentryController', QuickentryController);

    function QuickentryController($rootScope, $state, treeService) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.state = $state;

        treeService.sync.then(function(){

            var zTree = $.fn.zTree.getZTreeObj('openc3tree');
            var treeNode = zTree.getNodeByParam('id', $state.params.treeid);
            if(treeNode == null){
                //$state.go('home.e401');
                return;
            }

        });

        $rootScope.$on('$stateChangeSuccess', function(){

            vm.treeid = $state.params.treeid;
            vm.state = $state;
        });
    }

})();
