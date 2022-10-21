(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DeviceDataDetailController', DeviceDataDetailController)
        .filter('cut30', function () {
            return function (text) {
                if( text.length > 33 )
                {
                    return "..." + text.substr(text.length - 30)
                }
                return text;

            }
        });

    function DeviceDataDetailController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, uuid, $scope, $injector, treeid , type, subtype, homereload, selectedtimemachine ) {

        var vm = this;

        vm.treeid = treeid;
        vm.type = type;
        vm.subtype = subtype;
        vm.uuid = uuid;
        vm.treenamecol = '';

        vm.extcol = {};
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        vm.selectedtimemachine = selectedtimemachine;
        vm.data = [];
        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/device/detail/' + type + '/' + subtype +'/' + vm.treeid + '/' + uuid + '?timemachine=' + vm.selectedtimemachine ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.data = data.data;
                    vm.treenamecol = data.treenamecol;
                    vm.extcol = data.extcol;

                    vm.loadover = true;
                } else { 
                    toastr.error("加载数据失败:" + data.info)
                }
            });
        };

        vm.bindtree = function( newtree, title ){
            swal({
                title: title,
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.get('/api/agent/device/tree/bind/' + type + '/' + subtype +'/' + vm.uuid + '/' + newtree ).success(function(data){
                    if(data.stat == true) 
                    { 
                        toastr.success("操作完成");
                        vm.cancel();
                        homereload();
                    } else { 
                        toastr.error("操作失败:" + data.info)
                    }
                });
              });

        };
 
        vm.saveextcol = function( name, data ){
            swal({
                title: "保存",
                type: "warning",
                text: "修改:" + name,
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.post('/api/agent/device/extcol/' + type + '/' + subtype +'/' + vm.uuid + '/' + name, { "data": data } ).success(function(data){
                    if(data.stat == true) 
                    { 
                        toastr.success("操作完成");
                    } else { 
                        toastr.error("操作失败:" + data.info)
                    }
                });
              });
        };
 
        vm.chpasswd = function( data, dbaddrcolname, dbtype, password ){
            vm.dbaddr = '';
                angular.forEach(data, function (value) {
                    if( value[0] == dbaddrcolname )
                    {
                        vm.dbaddr = value[1];
                    }
                });

            swal({
                title: '修改账号',
                text: '保存' + dbtype + '://' + vm.dbaddr  + '账号',
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.post('/api/agent/device/chpassword', { "dbtype": dbtype, "dbaddr": vm.dbaddr, "passwd": password } ).success(function(data){
                    if(data.stat == true) 
                    { 
                        toastr.success("操作完成");
                    } else { 
                        toastr.error("操作失败:" + data.info)
                    }
                });
              });

        };
 
        vm.chauth = function( password ){
            swal({
                title: '修改账号信息',
                text: '保存账号',
                type: "warning",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true
            }, function(){
                $http.post('/api/agent/device/chpassword', { "dbtype": vm.type + '-' + vm.subtype , "dbaddr": vm.uuid, "passwd": password } ).success(function(data){
                    if(data.stat == true) 
                    { 
                        toastr.success("操作完成");
                    } else { 
                        toastr.error("操作失败:" + data.info)
                    }
                });
              });

        };

        vm.reload();

        vm.names=[];
        vm.search_init = function () {
            $http.get('/api/connector/connectorx/treemap').success(function (data) {
                vm.names = [];
                angular.forEach(data.data, function (value) {
                    vm.names.push(value.name);
                });

            });
         };

    }
})();
