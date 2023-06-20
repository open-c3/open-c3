(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('DeviceDataController', DeviceDataController)
        .filter('cut61', function () {
            return function (text) {
                if( text.length > 64 )
                {
                    return text.substr(0, 61) + "..."
                }
                return text;

            }
        });

    function DeviceDataController($state, $http, $scope, ngTableParams, $uibModal, treeService, genericService) {
        var vm = this;

        vm.exportDownload = genericService.exportDownload
        vm.tableData = []
        treeService.sync.then(function(){      // when the tree was success.
            vm.nodeStr = treeService.selectname();  // get tree name
        });

        vm.showfilter = 0;

        vm.chshowfilter = function(stat){
            vm.showfilter = stat;
            vm.grepfilter();
        }

        vm.treeid  = $state.params.treeid;
        vm.type    = $state.params.type;
        vm.subtype = $state.params.subtype;
        vm.grepdata = {};
        vm.selectedtimemachine = $state.params.timemachine;
        vm.timemachine = [];

        vm.filter = [];
        vm.filtergrep = [];
        vm.filterdata = {};

        vm.checkDataList = [];
        vm.checkboxes = {
          checked: false,
          items: {},
        };

        vm.grepdata._search_= sessionStorage.getItem('globalSearch')
        sessionStorage.removeItem('globalSearch')

        vm.grepfilter = function(){
            if( vm.showfilter )
            {
                vm.filtergrep = vm.filter;
            }
            else
            {
                vm.filtergrep = [];
                angular.forEach(vm.filter, function (value) {
                    if( vm.filtergrep.length < 6 )
                    {
                        vm.filtergrep.push(value)
                    }
                });
            }
        }

        vm.pointout = '';
        vm.reload = function () {
            vm.loadover = false;
            const grepDataJSON = JSON.parse(JSON.stringify(vm.grepdata));
            const newGrepdata = {};
            angular.forEach(grepDataJSON, function (value, key) {
              if (value !== '') {
                newGrepdata[key] = value
              }
            });
            $http.post('/api/agent/device/data/' + vm.type + '/' + vm.subtype + '/' + vm.treeid, { "grepdata": newGrepdata, "timemachine": vm.selectedtimemachine } ).success(function(data){
                if (data.stat){
                    vm.dealWithData(data.data);
                    vm.checkDataList = data.data
                    vm.dataTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                    vm.filter = data.filter;
                    angular.forEach(data.filterdata, function (value, key) {
                      value.unshift({name: '', count: key})
                      if (!vm.grepdata[key]) {
                        vm.grepdata[key] = ''
                      }
                    });
                    vm.filterdata = data.filterdata;
                    if( data.pointout == undefined || data.pointout == '' )
                    {
                        vm.pointout = '';
                    }
                    else
                    {
                        vm.pointout = data.pointout;
                    }
                    vm.grepfilter();
                    vm.loadover = true;
                }else {
                    swal({ title:'获取数据失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reload();
        sessionStorage.removeItem('globalSearch');

        vm.reloadtimemachine = function () {
            $http.get('/api/agent/device/timemachine' ).success(function(data){
                if (data.stat){
                    vm.timemachine = data.data;
                }else {
                    swal({ title:'获取时间机器列表失败', text: data.info, type:'error' });
                }
            });
        };
        vm.reloadtimemachine();

        vm.reset = function () {
            vm.grepdata = {};
            vm.reload();
        };

        vm.showdetail = function (uuid, type, subtype ) {
            $uibModal.open({
                templateUrl: 'app/pages/device/data/detail.html',
                controller: 'DeviceDataDetailController',
                controllerAs: 'devicedatadetail',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    getGroup: function () {return vm.getGroupInfo},
                    uuid: function () {return uuid},
                    type: function () {return type},
                    subtype: function () {return subtype},
                    treeid: function () {return vm.treeid},
                    name: function () {return name},
                    homereload: function () {return vm.reload},
                    selectedtimemachine: function () {return vm.selectedtimemachine},
                }
            });
        };

        vm.show = function ( uuid, type, subtype, config ) {
            if( config['type'] == 'blank' )
            {
                $http.post('/api/agent/device/detail/' + type+ '/' + subtype + '/' + vm.treeid +'/' + uuid + '?timemachine=' + vm.selectedtimemachine , { 'exturl': config['url'] }).success(function(data){
                    if (data.stat){
                        window.open(data.data, '_blank')
                    }else {
                        swal({ title:'获取URL地址失败', text: data.info, type:'error' });
                    }
                });
            }
        };

        vm.dealWithData = function (data) {
          vm.tableData = []
          vm.exportDownloadStr = `<tr><td>资源类型</td><td>基本信息</td><td>系统信息</td><td>联系信息</td></tr>`
          data.forEach(items => {
            vm.tableData.push({
              subtype: items.subtype || '',
              baseinfo: items.baseinfo || '',
              system: items.system || '',
              contact: items.contact || '',
            })
          })
        }

    vm.handleServiceTree = function (type) {
      const selectResourceArr = []
      angular.forEach(vm.checkboxes.items, function (value, key) {
        if (value) {
          selectResourceArr.push(key)
        }
      });
      const selectResDetail = vm.checkDataList.filter(item => selectResourceArr.find(cItem => cItem === item.uuid));

      if (type !== 'x') {
        $uibModal.open({
          templateUrl: 'app/pages/device/data/dialog/serviceTree.html',
          controller: 'ServiceTreeController',
          controllerAs: 'serviceTree',
          backdrop: 'static',
          size: 'md',
          keyboard: false,
          bindToController: true,
          resolve: {
            type: function () { return type },
            treeid: function () { return vm.treeid },
            selectResDetail: function () { return selectResDetail},
          }
        });
      } else {
        swal({
          title: '归还资源到资源池',
          type: "warning",
          showCancelButton: true,
          confirmButtonColor: "#DD6B55",
          cancelButtonText: "取消",
          confirmButtonText: "确定",
          closeOnConfirm: true
        }, function () {
          angular.forEach(selectResDetail, function (item) {
            $http.post(`/api/agent/device/tree/bind/${item.type}/${item.subtype}/${item.uuid}/${type}`).success(function (data) {
              if (data.stat == true) {
                toastr.success("操作完成");
                vm.cancel();
                vm.reload();
              } else {
                toastr.error("操作失败:" + data.info)
              }
            });
          })
        });
      }
    }

    // 监听全选checkbox
    $scope.$watch(function () {return vm.checkboxes.checked }, function (value) {
      angular.forEach(vm.checkDataList, function (item, index, array) {
        vm.checkboxes.items[[array[index].uuid]] = value
      });
      vm.checkboxes.itemsNumber = Object.values(vm.checkboxes.items).filter(item => item === true).length
      let nodeList = []
      for (let key in vm.checkboxes.items) {
        nodeList.push(String(key))
      }
    }, true);

    // 监听单个列表项的checkbox
    $scope.$watch(function () { return vm.checkboxes.items }, function (value) {
        var checked = 0, unchecked = 0
        angular.forEach(vm.checkDataList, function (item, index, array) {
          checked += (vm.checkboxes.items[array[index].uuid]) || 0;
          unchecked += (!vm.checkboxes.items[array[index].uuid]) || 0;
        });
        if (vm.checkDataList.length > 0 && ((unchecked == 0) || (checked == 0))) {
          vm.checkboxes.checked = (checked == vm.checkDataList.length);
        }
        vm.checkboxes.itemsNumber = checked
        angular.element(document.getElementsByClassName("select-all")).prop("indeterminate", (checked != 0 && unchecked != 0));
      }, true);
    }
})();
