(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('SysctlController', SysctlController);

    /** @ngInject */
    function SysctlController($http) {

        var vm = this;

        vm.sysctl = {};
        vm.menu = [];

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/connector/sysctl' ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.sysctl = data.data
                    vm.menu = data.ext.menu;
                    vm.loadover = true;
                } else { 
                    swal({ title: "加载配置失败!", text: data.info, type:'error' });
                }
            });
        };

        vm.save = function () {

          swal({
            title: "保存系统参数配置",
            text: "保存？",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.post('/api/connector/sysctl', { config: vm.sysctl } ).success(function(data){
                if(data.stat == true) 
                { 
                    swal({ title: "保存成功!", text: '保存成功', type:'success' });
                    
                } else { 
                    swal({ title: "保存失败!", text: data.info, type:'error' });
                }
            });
          });
        };
        vm.reload()

    }
})();

