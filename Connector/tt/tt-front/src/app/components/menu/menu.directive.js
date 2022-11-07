(function(){
    'use strict';

    angular
        .module('cmdb')
        .directive('c3menu', menu);

    /** @ngInject */
    function menu() {

        var directive = {

            //link: linkFunc,
            restrict: 'E',
            templateUrl: 'app/components/menu/menu.html',
            scope: {},
            controller: menuController,
            controllerAs: 'menu'
        };

        return directive;

        /** @ngInject */
        function menuController($state, adminService) {

            var vm = this;

            vm.states = $state;

            adminService.getData().then(function(data){
                if (data){
                    vm.isAdmin = true;
                }
            });

    }

}

})();
