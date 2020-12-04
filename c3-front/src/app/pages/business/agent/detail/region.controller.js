(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('AgentRegionController', AgentRegionController);

    function AgentRegionController($uibModalInstance, $http, $state, nodeStr, ngTableParams, reloadhome ) {

        var vm = this;
        vm.nodeStr = nodeStr;

        vm.cancel = function(){ $uibModalInstance.dismiss(); reloadhome();};

        vm.treeid = $state.params.treeid;

        vm.selected = {}
        vm.reload = function(){
            vm.loadover =false;
            $http.get('/api/agent/region/' + vm.treeid + '?relation=1').success(function(data){
                vm.list = data.data;
                $http.get('/api/agent/project_region_relation/' + vm.treeid ).success(function(data){
                    vm.relation = {};
                    for( var i in data.data )
                    {
                        vm.relation[data.data[i].regionid]='1';
                    }

                    for( var i =0; i< vm.list.length; i++ )
                    {
                        if(vm.relation.hasOwnProperty( vm.list[i].id ))
                        {
                            vm.list[i].selected = true;
                            vm.selected[vm.list[i].id] = true;
                        }
                        else
                        {
                            vm.list[i].selected = false;
                            vm.selected[vm.list[i].id] = false;
                        }
                    }
                    vm.proxylistTable = new ngTableParams({count:500}, {counts:[],data:vm.list});
                    vm.loadover =true;
                });
            });

        };

        vm.reload();

        vm.showRegion = function( b ){
            vm.showRegionBool = b;
        }
 
        vm.createRegion = function(){
          swal({
            title: "是否添加区域",
            text: "区域名:"+ vm.regionText,
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.post('/api/agent/region/' + vm.treeid, { "name": vm.regionText}).success(function(data){
                vm.regionText = '';
                vm.reload();
            });
          });
        }

        vm.deleteRegion = function(id) {
          swal({
            title: "是否要删除该区域",
            text: "将会删除区域下所有的数据",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.delete('/api/agent/region/' + vm.treeid+'/'+id ).success(function(data){
                vm.reload();
            });
          });
        }
        vm.save =function() {
          swal({
            title: "保存区域选择",
            text: "取消选择的区域的proxy和agent将被删除",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            for( var i =0; i< vm.list.length; i++ ){
                if(vm.selected[vm.list[i].id] != vm.list[i].selected)
                {
                    if( vm.list[i].selected )
                    {
                        $http.post('/api/agent/project_region_relation/' + vm.treeid, { "regionid": vm.list[i].id}).success(function(data){
                            console.log( data )
                        });
                    }
                    else
                    {
                        $http.delete('/api/agent/project_region_relation/' + vm.treeid+'/'+vm.list[i].id ).success(function(data){
                            console.log( data )
                        });
                    }
                }
            }
          });
        }
    }
})();
