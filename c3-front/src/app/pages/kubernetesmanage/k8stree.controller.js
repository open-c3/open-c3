(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesK8sTreeController', KubernetesK8sTreeController);

    function KubernetesK8sTreeController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, homereload ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.change = 0;
        vm.cancel = function(){ 
            if( vm.change === 1 )
            {
                homereload();
            }
            $uibModalInstance.dismiss();
        };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/ticket/KubeConfig" ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.k8sTable = new ngTableParams({count:25}, {counts:[],data:data.data});

                    $http.get("/api/ci/k8stree/" + vm.treeid ).success(function(data){
                        if(data.stat == true) 
                        { 
                          vm.loadover = true;
                          vm.k8stree = data.data;

                        } else { 
                            toastr.error("加载关联表失败:" + data.info)
                        }
                    });

                } else { 
                    toastr.error("加载kubernetes集群列表失败:" + data.info)
                }
            });
        };
        vm.reload();

        vm.addK8sTree = function(k8sid){
            vm.loadover = false;
            $http.post("/api/ci/k8stree/"+ vm.treeid + "/" + k8sid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.change = 1;
                    vm.reload();
                } else { 
                    toastr.error("添加关联失败:" + data.info)
                }
            });
        };
         vm.delK8sTree = function(k8sid){
            vm.loadover = false;
            $http.delete("/api/ci/k8stree/"+ vm.treeid + "/" + k8sid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.change = 1;
                    vm.reload();
                } else { 
                    toastr.error("删除关联失败:" + data.info)
                }
            });
        };
 
    }
})();
