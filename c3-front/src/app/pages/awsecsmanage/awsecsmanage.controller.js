(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AwsecsmanageController', AwsecsmanageController)
        .filter('cut', function () {
            return function (text) {
                if( text.length > 43 )
                {
                    return "..." + text.substr(text.length - 40)
                }
                return text;

            }
        });

    function AwsecsmanageController($scope, $state, $http, treeService, ngTableParams, $injector, $timeout, genericService, $uibModal ) {

        var vm = this;
        var toastr = toastr || $injector.get('toastr');
        vm.treeid = $state.params.treeid;

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function () {
            vm.loadover = false;
            $http.get('/api/ci/awsecs/' + vm.treeid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.dataTable = new ngTableParams({count:10}, {counts:[],data:response.data.data});
                        vm.loadover = true;
                    }else {
                        toastr.error( "获取列表失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取列表失败: " + response.status )
                });
        };

        vm.reload();

        vm.describeec = function (ticketid, region, cluster,service,taskdef) {
            var cmd = "#!awsecs\nregion: " + region + "\ncluster: " + cluster +  "\nservice: " + service +  "\ntask-definition: " + taskdef;
            var data = { "cmd": cmd, "max": "max", "min": "min", "name": service, "ticketid": ticketid };
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/describeecs.html',
                controller: 'KubernetesDescribeEcsController',
                controllerAs: 'kubernetesdescribeecs',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return 'vm.project.ci_type_kind'},
                    name: function () {return 'name'},
                    data: function () {return data},
                    namespace: function () {return 'vm.project.ci_type_namespace'},
                    ticketid: function () {return ticketid},
                }
            });
        };
    }

})();
