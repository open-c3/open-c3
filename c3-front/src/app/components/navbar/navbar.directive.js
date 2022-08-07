(function() {
    'use strict';

    angular
        .module('openc3')
        .directive('cmnavbar', cmnavbar);

    /** @ngInject */
    function cmnavbar() {
        var directive = {

            restrict: 'E',
            templateUrl: 'app/components/navbar/navbar.html',
            scope: {},
            controller: NavbarController,
            controllerAs: 'nav'
        };

        return directive;

        /** @ngInject */
        function NavbarController($scope, $location, $http, $state, treeService, $window, ssoService) {

            var vm = this;
            vm.zTree = '';
            treeService.sync.then(function(data) {
      
              vm.zTree = $.fn.zTree.getZTreeObj('openc3tree');
            });
              vm.select_map = {};
              vm.search_init = function () {
                vm.names = [];
                $http.get('/api/connector/connectorx/treemap').success(function (data) {
                  vm.name = data.data;
                  angular.forEach(vm.name, function (value) {
                    vm.names.push(value.name);
                    vm.select_map[value.name] = value.id;
                  });
                });
              };
      
            vm.searchNode = function (item, model, label, event){
              var node = vm.zTree.getNodeByParam("id", vm.select_map[item]);
              vm.zTree.selectNode(node);
              vm.zTree.expandNode(node);
              vm.search_init(event)
            };

            $scope.envir = 'test';
            $scope.allUrls = [ ];
            $scope.nextUrls = { };
            $scope.mulUrls = { };
            $scope.ciUrls = { };
            vm.logout = function(){
                var siteaddr = window.location.protocol + '//' + window.location.host;
                $http.get('/api/connector/connectorx/ssologout?siteaddr=' + siteaddr ).success(function(data){
                    if(data.data)
                    {
                        $window.location.href=data.data
                    }
                    else
                    {
                        $window.location.reload();
                    }
                });
            };

            vm.chpasswd = function(){
                var siteaddr = window.location.protocol + '//' + window.location.host;
                $window.location.href=ssoService.chpasswd + '?siteaddr=' + siteaddr ;
            };

            vm.state = $state;
            vm.state.params.treeid = vm.state.params.treeid ? vm.state.params.treeid : -1;

            // get user
            $http.get('/api/connector/connectorx/sso/userinfo').success(function(data){
                vm.user = data;
            });

            var hash = $location.host();
            var envir = hash.split(".")[0];
            var envir_name = hash.split(".")[1];

            if (envir == 'dev' || envir == 'test'){
                $scope.envir = 'test';
            }else{
                $scope.envir = 'online';
            }

            vm.openCI = function (idx, next_name) {
                var ciurl = $scope.ciUrls[$scope.envir][idx].url + "/#/dashboard/" + vm.state.params.treeid;
                if ($scope.envir == "test"){
                    window.open(ciurl, '_blank');
                    return
                }
                if (envir != next_name){
                    window.open(ciurl, '_blank')
                }else {
                    return
                }

            };
            vm.openMul = function (idx, next_name) {
                var ciurl = $scope.mulUrls[$scope.envir][idx].url + vm.state.params.treeid;
                if ($scope.envir == "test"){
                    window.open(ciurl, '_blank');
                    return
                }
                if (envir != next_name){
                    window.open(ciurl, '_blank')
                }else {
                    return
                }
            };
            vm.openUrl = function (idx, next_name) {
                var nextUrl = '';
                window.open(nextUrl, '_blank')
            }
        }
    }

})();
