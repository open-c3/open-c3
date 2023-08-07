(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('BusinessBpmController', BusinessBpmController);

    function BusinessBpmController($timeout, $state, $http, $uibModal, $scope, treeService, ngTableParams, resoureceService, scriptId, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.bpmTypeMap = {
          sys: '系统内置',
          diy: '自定义'
        }
        vm.bpmShowMap = {
          0: '否',
          1: '是'
        };

        vm.deleteBpm = function(name){
            swal({
                title: "删除",
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.delete( '/api/job/bpm/manage/conf/' + name  ).success(function(data){
                    if (data.stat){
                        vm.reload();
                    }else {
                        swal({ title:'删除失败', text: data.info, type:'error' });
                    }
 
                });
              });
        };

        vm.Reset = function () {
            vm.bpmname = "";
            vm.reload()
        };

        vm.reload = function () {
            vm.loadover = false
            var get_data = {};
            if (vm.bpmname){
                get_data.name=vm.bpmname
            }
            $http({
                method:'GET',
                url:'/api/job/bpm/manage/menu',
                params:get_data
            }).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        const hasFilterData = response.data.data.map(item => {
                          item['bpmTypeStatus'] = vm.bpmTypeMap[item.type]
                          item['bpmShowStatus'] = vm.bpmShowMap[item.show]

                          return item
                        })
                        vm.dataTable = new ngTableParams({count:10}, {counts:[],data:hasFilterData});
                    }else {
                        swal('获取列表失败', response.data.info, 'error');
                    }
                },
                function errorCallback(response) {
                    swal('获取列表失败', response.status, 'error');
                }
            );

        };

        vm.reload();

        vm.addBpm = function () {
          $state.go('home.business.bpmcreate', { treeid: vm.treeid } );
        }

        vm.runBpm = function (name, show) {
          swal({
            title: `${show === '0'? '确定显示？': '确定隐藏？'}`,
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.post(`/api/job/bpm/manage/show/${name}/${Number(!+show)}`).success(function(data){
              if (data.stat){
                vm.reload();
                swal({ title: '执行成功', type: 'success' });
              }else {
                swal({ title:'执行失败', text: data.info, type:'error' });
              }
            });
          });
        }

        vm.editBpm = function (name) {
          $state.go('home.business.bpmedit', {treeid: vm.treeid, name})
        }
    }

})();
