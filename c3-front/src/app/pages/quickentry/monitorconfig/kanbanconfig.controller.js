(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KanbanConfigController', KanbanConfigController);

    function KanbanConfigController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, homereload ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ 
            homereload();
            $uibModalInstance.dismiss();
        };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/agent/monitor/config/kanban/" + vm.treeid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.loadover = true;
                    vm.kanbanTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                } else { 
                    toastr.error("加载看版列表失败:" + data.info)
                }
            });
        };
        vm.reload();

        vm.addKanban = function(){
            $http.post("/api/agent/monitor/config/kanban/"+ vm.treeid, { name: vm.kanbanName, url: vm.kanbanUrl }  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.reload();
                } else { 
                    toastr.error("添加看版:" + data.info)
                }
            });
        };
         vm.delKanban = function(kanbanid){
            $http.delete("/api/agent/monitor/config/kanban/"+ vm.treeid + "/" + kanbanid ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.reload();
                } else { 
                    toastr.error("删除看版失败:" + data.info)
                }
            });
        };

        vm.setDefaultKanban = function( kanbanid, stat ){
            $http.post("/api/agent/monitor/config/kanban/setdefault/"+ vm.treeid + "/" + kanbanid, { stat: stat }  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.reload();
                } else { 
                    toastr.error("设置默认看版失败:" + data.info)
                }
            });
        };

    }
})();
