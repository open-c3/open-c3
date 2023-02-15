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
        vm.grpcol = {};
        
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        vm.selectedtimemachine = selectedtimemachine;
        vm.data = [];

        vm.formatArr = function (arr) {
          let map = new Map();
          for (let item of arr) {
            if (!map.has(item.name)) {
              map.set(item.name, item);
            }
          }
          return [...map.values()];
        }

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/device/detail/' + type + '/' + subtype +'/' + vm.treeid + '/' + uuid + '?timemachine=' + vm.selectedtimemachine ).success(function(data){
              const newData = JSON.parse(JSON.stringify(data.data))
              const addinfo = [...data.grpcol.system, ...data.grpcol.baseinfo]
              const disposeGrpcol = []
              newData.forEach((dataItems, dataIndex) => {
                const newSystem = []
                const newBaseinfo = []

              data.grpcol.system.map(info => {
                if (info.prefix) {
                  addinfo.filter(cItem => !!cItem.prefix).map(preItem => {
                    newSystem.push(...dataItems.filter(item => item[0].indexOf(preItem.prefix) === 0).map(item => {
                      return {
                        name: item[0],
                        value: item[1]
                      }
                    }))
                  })
                } else {
                  newSystem.push(...dataItems.filter(item => item[0] === info.name).map(item => {
                    info.name = item[0]
                    info.value = item[1]
                    if(info.success) {
                      info.isSuccess = !!info.success.find(d => d === item[1])
                    }
                    return info
                  }))
                }
              })  

              data.grpcol.baseinfo.map(info => {
                if (info.prefix) {
                  addinfo.filter(cItem => !!cItem.prefix).map(preItem => {
                    newBaseinfo.push(...dataItems.filter(item => item[0].indexOf(preItem.prefix) === 0).map(item => {
                      return {
                        name: item[0],
                        value: item[1]
                      }
                    }))
                  })
                } else {
                  newBaseinfo.push(...dataItems.filter(item => item[0] === info.name).map(item => {
                    info.name = item[0]
                    info.value = item[1]
                    if(info.success) {
                      info.isSuccess = !!info.success.find(d => d === item[1])
                    }
                    return info
                  }))
                }
              })
              const newGrpcol = [
                ...data.grpcol.system.filter(item => !!item.name).map(item => item.name),
                ...data.grpcol.baseinfo.filter(item => !!item.name).map(item => item.name)
              ]
              if (addinfo.find(cItem => cItem.prefix)) {
                newGrpcol.push(
                    ...dataItems.filter(item => item[0].indexOf(addinfo.find(cItem => cItem.prefix).prefix) === 0).map(item => item[0])
                ) 
              }
              const newOtherinfo = dataItems.filter(item => !newGrpcol.find(cItem => cItem === item[0]))
              disposeGrpcol.push ({
                index:dataIndex,
                system: vm.formatArr(newSystem),
                baseinfo: vm.formatArr(newBaseinfo),
                otherinfo: newOtherinfo,
                systemFlag : true,
                baseinfoFlag : true,
                otherinfoFlag : false,
                operationFlag: true,
              })
              })
              if(data.stat == true) 
                { 
                    vm.data = data.data;
                    vm.treenamecol = data.treenamecol;
                    vm.extcol = data.extcol;

                    vm.loadover = true;
                    vm.loadover = true;
                    vm.grpcol = disposeGrpcol
                } else { 
                    toastr.error("加载数据失败:" + data.info)
                }
            });
        };

        vm.showFlag = function (index, type, flag) {
          vm.grpcol.forEach(item => {
            if (item.index === index) {
            switch (type) {
              case 'systemFlag':
                item.systemFlag = !flag
                break
              case 'baseinfoFlag':
                item.baseinfoFlag = !flag
                break
              case 'otherinfoFlag':
                item.otherinfoFlag = !flag
                break
              case 'operationFlag':
                item.operationFlag = !flag
                break
            }
            }
          })
        }

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
