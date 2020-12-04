(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('ConnectorConfigController', ConnectorConfigController);

    /** @ngInject */
    function ConnectorConfigController($http) {

        var vm = this;

        vm.config = {};
        vm.configlist = [];
        vm.name = 'current'

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/connector/config?name=' + vm.name ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.config = data.data
                    $http.get('/api/connector/config/list' ).success(function(data){
                        if(data.stat == true) 
                        { 
                            vm.configlist = data.data
                            vm.loadover = true;
                        } else { 
                            swal({ title: "加载连接器列表失败!", text: data.info, type:'error' });
                        }
                    });
                } else { 
                    swal({ title: "加载连接器配置失败!", text: data.info, type:'error' });
                }
            });
        };

        vm.save = function () {

          swal({
            title: "保存连接器配置",
            text: "保存后服务会自动重启",
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function(){
            $http.post('/api/connector/config', { config: vm.config } ).success(function(data){
                if(data.stat == true) 
                { 
                    swal({ title: "保存成功!", text: '系统正在重启，20秒后刷新页面', type:'success' });
                    
                } else { 
                    swal({ title: "保存失败!", text: data.info, type:'error' });
                }
            });
          });
        };
        vm.reload()

    }
})();

