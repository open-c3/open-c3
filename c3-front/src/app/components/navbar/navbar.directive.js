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
                $http.get('/api/connector/connectorx/ssologout').success(function(data){
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
                var siteaddr = window.location.host;
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
            }else if(envir == "orionstar"){
                $scope.envir = "orionstar";
            }else if(envir == "htorionstar"){
                $scope.envir = "htorionstar";
            }else{
                $scope.envir = 'online';
            }


            // if (hash.indexOf("ci") != -1 && hash.indexOf("liveme") != -1){
            //     $scope.allUrls = [];
            // }

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
                if ($scope.envir == "online"){
                    if (hash.indexOf("txy") != -1 || hash.indexOf("liveme") != -1){
                        var envir_name = hash.split(".")[1];
                        if (hash.indexOf("txy") != -1){
                            next_name = next_name +"txy"
                        }
                    }else {
                        var envir_name = hash.split(".")[0];
                    }
                    if (envir_name != next_name){
                        // var replaceUrl = hash.replace(envir_name, next_name);
                        nextUrl = $scope.nextUrls[next_name] + vm.state.params.treeid;
                    }else {
                        return
                    }
                }else if ($scope.envir == "htorionstar") {
                    if (hash.indexOf("htorionstar") != -1){
                        var envir_name = hash.split(".")[1];
                        if (hash.indexOf("htorionstar") != -1){
                            next_name = next_name +"htorionstar"
                        }
                    }else {
                        var envir_name = hash.split(".")[0];
                    }
                    if (envir_name != next_name){
                        // var replaceUrl = hash.replace(envir_name, next_name);
                        nextUrl = $scope.nextUrls[next_name] + vm.state.params.treeid;
                    }else {
                        return
                    }
                }else if ($scope.envir == "orionstar") {
                    if (hash.indexOf("orionstar") != -1 ){
                        var envir_name = hash.split(".")[1];
                        if (hash.indexOf("orionstar") != -1){
                            next_name = next_name +"orionstar"
                        }
                    }else {
                        var envir_name = hash.split(".")[0];
                    }
                    if (envir_name != next_name){
                        // var replaceUrl = hash.replace(envir_name, next_name);
                        nextUrl = $scope.nextUrls[next_name] + vm.state.params.treeid;
                    }else {
                        return
                    }
                }else if ($scope.envir == "test"){
                    var envir_name = hash.split(".")[1];
                    if (envir_name != next_name){
                        // var replaceUrl = hash.replace(envir_name, next_name);
                        nextUrl = $scope.nextUrls[next_name + "test"] + vm.state.params.treeid;
                    }else {
                        return
                    }
                }
                window.open(nextUrl, '_blank')
            }
        }
    }

})();
