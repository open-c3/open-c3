(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesmanageController', KubernetesmanageController);

    function KubernetesmanageController($scope, $state, $http, treeService, ngTableParams, $injector, $timeout, genericService, $uibModal ) {

        var vm = this;
        var toastr = toastr || $injector.get('toastr');
        vm.treeid = $state.params.treeid;

        vm.selecteClusterId = $state.params.clusterid;
        vm.selecteCluster = {};
        if( vm.selecteClusterId == undefined )
        {
            vm.selecteClusterId = '0'
        }

        vm.selectednamespace = $state.params.namespace;
        if( vm.selectednamespace == undefined )
        {
            vm.selectednamespace = ''
        }

        vm.selectedStat = $state.params.stat;
        if( vm.selectedStat == undefined )
        {
            vm.selectedStat = ''
        }

        vm.namespace = [];

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.refreshPage = function (namespace, clusterid, stat ) {
            $state.go('home.kubernetesmanage', {treeid:vm.treeid, namespace: namespace, stat: stat, clusterid: clusterid});
        }

        $scope.choiceNamespace = vm.selectednamespace;
        $scope.choiceStat = vm.selectedStat;
        $scope.choiceClusterId = vm.selecteClusterId;

        $scope.$watch('choiceNamespace', function () {
                vm.refreshPage( $scope.choiceNamespace, $scope.choiceClusterId, $scope.choiceStat )
        });

        $scope.$watch('choiceStat', function () {
                vm.refreshPage( $scope.choiceNamespace, $scope.choiceClusterId, $scope.choiceStat )
        });

        $scope.$watch('choiceClusterId', function () {
                vm.refreshPage( $scope.choiceNamespace, $scope.choiceClusterId, $scope.choiceStat )
        });

        vm.deploymentCount = 0;
        vm.deploymentReady = 0;
        vm.daemonsetCount = 0;
        vm.serviceCount = 0;
        vm.podCount = 0;
        vm.replicasetCount = 0;
 
        vm.loadoverA = false;
        vm.loadoverB = false;

        vm.reload = function () {
            $http.get('/api/ci/ticket?type=KubeConfig' ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.clusterlist = response.data.data; 
                        $scope.clusterCount = vm.clusterlist.length;

                        if( vm.selecteClusterId > 0 ){
                            angular.forEach(vm.clusterlist, function (value, key) {
                                if( value.id ==  vm.selecteClusterId )
                                {
                                    vm.selecteCluster = value;
                                }
                            });
                        }

                        vm.loadoverA = true;
                    }else {
                        toastr.error( "获取集群列表失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取集群列表失败: " + response.status )
                });

            if( vm.selecteClusterId <= 0 )
            {
                vm.loadoverB = true;
                return;
            }

            $http.get("/api/ci/kubernetes/app?ticketid=" + vm.selecteClusterId + "&namespace=" + vm.selectednamespace + "&status=" + vm.selectedStat ).then(
                function successCallback(response) {
                    if (response.data.stat){

                        vm.namespace = response.data.namespace; 

                        vm.deploymentTable = new ngTableParams({count:10}, {counts:[],data:response.data.data.deployment});
                        vm.deploymentCount = response.data.data.deployment.length;
                        vm.deploymentReady = response.data.deploymentready;

                        vm.daemonsetTable = new ngTableParams({count:10}, {counts:[],data:response.data.data.daemonset});
                        vm.daemonsetReady = response.data.daemonsetready;
                        vm.daemonsetCount = response.data.data.daemonset.length;

                        vm.serviceTable = new ngTableParams({count:10}, {counts:[],data:response.data.data.service});
                        vm.serviceCount = response.data.data.service.length; 

                        vm.podTable = new ngTableParams({count:10}, {counts:[],data:response.data.data.pod});
                        vm.podReady = response.data.podready;
                        vm.podRunning = response.data.podrunning;
                        vm.podCount = response.data.data.pod.length;

                        vm.replicasetTable = new ngTableParams({count:10}, {counts:[],data:response.data.data.replicaset});
                        vm.replicasetReady = response.data.replicasetready;
                        vm.replicasetCount = response.data.data.replicaset.length;

                        vm.loadoverB = true;
                    }else {
                        toastr.error( "获取集群中应用数据失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取集群中应用数据失败: " + response.status )
                });
        };

        vm.reload();

        vm.edityaml = function (type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/edityaml.html',
                controller: 'KubernetesEditYamlController',
                controllerAs: 'kubernetesedityaml',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    namespace: function () {return namespace},
                    ticketid: function () {return vm.selecteClusterId},
                    clusterinfo: function () {return vm.selecteCluster},
                }
            });
        };

        vm.apply = function () {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/apply.html',
                controller: 'KubernetesApplyController',
                controllerAs: 'kubernetesapply',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    ticketid: function () {return vm.selecteClusterId},
                    clusterinfo: function () {return vm.selecteCluster},
                }
            });
        };


        vm.describe = function (type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/describe.html',
                controller: 'KubernetesDescribeController',
                controllerAs: 'kubernetesdescribe',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    namespace: function () {return namespace},
                    ticketid: function () {return vm.selecteClusterId},
                }
            });
        };

        vm.setimage = function (type,name,namespace,image,container) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/setimage.html',
                controller: 'KubernetesSetImageController',
                controllerAs: 'kubernetessetimage',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    image: function () {return image},
                    container: function () {return container},
                    namespace: function () {return namespace},
                    ticketid: function () {return vm.selecteClusterId},
                    clusterinfo: function () {return vm.selecteCluster},
                }
            });
        };

        vm.rollback = function (type,name,namespace,image,container) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/rollback.html',
                controller: 'KubernetesRollbackController',
                controllerAs: 'kubernetesrollback',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    namespace: function () {return namespace},
                    ticketid: function () {return vm.selecteClusterId},
                    clusterinfo: function () {return vm.selecteCluster},
                }
            });
        };

        vm.setreplicas = function (type,name,namespace,replicas) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/setreplicas.html',
                controller: 'KubernetesSetReplicasController',
                controllerAs: 'kubernetessetreplicas',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    replicas: function () {return replicas},
                    namespace: function () {return namespace},
                    ticketid: function () {return vm.selecteClusterId},
                    clusterinfo: function () {return vm.selecteCluster},
                }
            });
        };

        vm.addCluster = function () {
            $uibModal.open({
                templateUrl: 'app/pages/global/ticket/createTicket.html',
                controller: 'CreateTicketController',
                controllerAs: 'createticket',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    ticketid: function () {},
                    homereload: function () { return vm.reload },
                    type: function () { return 'create' },
                    title: function () { return '添加kubernetes集群' },
                    point: function () { return 'KubeConfig' },
                }
            });

        };

    }

})();
