(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('AgentHostController', AgentHostController);

    /** @ngInject */
    function AgentHostController($scope, $uibModalInstance, $http, $state, nodeStr, regionid, ngTableParams,selectip) {

        var vm = this;
        vm.nodeStr = nodeStr;
        vm.regionid = regionid;
        $scope.all_name = false;
        $scope.all_inip = false;
        $scope.all_exip = false;

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        vm.treeid = $state.params.treeid;

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/nodeinfo/' + vm.treeid).success(function(data){
                vm.list = data.data;
                vm.hostlistTable = new ngTableParams({count:500}, {counts:[],data:vm.list});
                vm.loadover = true;
            });
        };

        vm.reload();

        vm.install = { type: 'host' };
        vm.showHost = function( b ){
            vm.showHostBool = b;
        }
 
        vm.check_name = function(all_name) {
            for (var i = vm.list.length - 1; i >= 0; i--) {
                vm.list[i].selected_name = all_name;
            }
            $scope.s_name = all_name;
        };
        vm.check_inip = function(all_inip) {
            for (var i = vm.list.length - 1; i >= 0; i--) {
                vm.list[i].selected_inip = all_inip;
            }
            $scope.s_inip = all_inip;
        };
        vm.check_exip = function(all_exip) {
            for (var i = vm.list.length - 1; i >= 0; i--) {
                vm.list[i].selected_exip = all_exip;
            }
            $scope.s_exip = all_exip;
        };

        vm.save =function() {
            var arr = new Array();
            for( var i =0; i< vm.list.length; i++ ){
                if( vm.list[i].selected_name )
                {
                    arr.push( vm.list[i].name );
                }
                if( vm.list[i].selected_inip )
                {
                    arr.push( vm.list[i].inip );
                }
                if( vm.list[i].selected_exip )
                {
                    arr.push( vm.list[i].exip  );
                }
                selectip( arr.join( "," ) );
 
            }
            $uibModalInstance.dismiss(); 

        }

        vm.installHost = function() {
            $http.post('/api/agent/install/' + vm.treeid +'/' + regionid, vm.install ).success(function(data){
                vm.install = { type : 'host'};
            });
        }
    }

})();
