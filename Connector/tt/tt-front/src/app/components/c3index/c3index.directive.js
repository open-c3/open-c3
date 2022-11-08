(function(){
    'use strict';
    angular
        .module('cmdb')
        .directive('c3index', c3index);
    /** @ngInject */
    function c3index() {
        var directive = {
            restrict: 'E',
            templateUrl: 'app/components/c3index/c3index.html',
            scope: {},
            controller: c3indexController,
            controllerAs: 'c3index'
        };
        return directive;

        /** @ngInject */
        function c3indexController($state, $http) {

            if ($state.current.name=="home"){
                var vm = this;

                // 未解决事件列表
                $http.get('/api/tt/search/index/menulist').success(function(data){
                    vm.menulist = data.data;
                });

                // 快速搜索
                $http.get('/api/tt/search/index/assignme').success(function(data){
                    vm.assignme = data.data;
                });
                $http.get('/api/tt/search/index/selfsubmit').success(function(data){
                    vm.selfsubmit = data.data;
                });
                $http.get('/api/tt/search/index/emaillistme').success(function(data){
                    vm.emaillistme = data.data;
                });
                $http.get('/api/tt/search/index/level12').success(function(data){
                    vm.level12 = data.data;
                });

            }

        }

    }

})();
