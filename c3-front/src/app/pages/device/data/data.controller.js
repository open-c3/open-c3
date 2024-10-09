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

    function DeviceDataController($state, $http, $scope, $injector, ngTableParams, $uibModal, treeService, $rootScope) {
        var vm = this;
        var toastr = toastr || $injector.get('toastr');

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
        vm.downloadTitle = [];
        vm.downloadData = [];

        vm.filter = [];
        vm.filtergrep = [];
        vm.filterdata = {};

        vm.checkDataList = [];
        vm.checkboxes = {
          checked: false,
          items: {},
        };

        vm.tablePageSizeOption = [
          {
            label: '全部',
            value: ''
          },
          {
            value: 200,
            label: '200条'
          }
        ]

        vm.operateMap = {
          blank: '/assets/images/cmdb-monitor.png',
          tags: '/assets/images/cmdb-tags.png',
          modal: '/assets/images/cmdb-detail.png',
          table: '/assets/images/cmdb-table.png',
          button:'/assets/images/cmdb-button.png',
          select:'/assets/images/cmdb-select.png',
        }

        vm.specificType = ['table','button']

        vm.tableClassificationMap =  {
          '后端机器': '/assets/images/cmdb-server.png',
          '开机': '/assets/images/cmdb-startup.png',
          '关机':'/assets/images/cmdb-shutdown.png',
          '终端':'/assets/images/cmdb-terminal.png',
          '控制台':'/assets/images/cmdb-console.jpg',
        }
        vm.tablePageSize = 200

        vm.pageSizeOption = [20, 30, 50, 100, 200];

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
            $http.post('/api/agent/device/data/' + vm.type + '/' + vm.subtype + '/' + `${vm.deptFilter ? 0: vm.treeid}`, { "grepdata": newGrepdata, "timemachine": vm.selectedtimemachine, "toxlsx": 1, pageSize: vm.tablePageSize } ).success(function(data){
                if (data.stat){
                    vm.checkDataList = data.data
                    vm.dataTable = new ngTableParams({count:25}, {counts:vm.pageSizeOption,data:data.data});
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

        vm.pageSizeChange = function (value) {
          vm.tablePageSize = value
          vm.reload()
        }

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
            vm.tablePageSize = 200
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

        vm.newremarks = {};
        vm.updateremarks = function (id, data) {
            vm.newremarks[id] = data;
        }
        vm.showremarks = function (id,uuid, type, subtype ) {
            $uibModal.open({
                templateUrl: 'app/pages/device/data/remarks.html',
                controller: 'DeviceDataRemarksController',
                controllerAs: 'devicedataremarks',
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
                    id: function () {return id},
                    updateremarks: function () {return vm.updateremarks},
                }
            });
        };

        vm.showTypeOperate = {
          blank: function (uuid, type, subtype, config) {
            var siteaddr = window.location.protocol + "//" + window.location.host;
            $http.post(`/api/agent/device/detail/${type}/${subtype}/${vm.treeid}/${uuid}?siteaddr=${siteaddr}&timemachine=${vm.selectedtimemachine}`, { 'exturl': config['url'] }).success(function (data) {
              if (data.stat) {
                window.open(data.data, '_blank')
              } else {
                swal({ title: '获取URL地址失败', text: data.info, type: 'error' });
              }
            });
          },
          modal: function (uuid, type, subtype, config) {
            $uibModal.open({
              templateUrl: 'app/pages/device/data/dialog/resourceDetail/resourceDetail.html',
              controller: 'ResourceDetailController',
              controllerAs: 'resourceDetail',
              backdrop: 'static',
              size: 'lg',
              keyboard: false,
              bindToController: true,
              resolve: {
                config: function () {return config},
                uuid: function () {return uuid},
                type: function () {return type},
                subtype: function () {return subtype},
                treeid: function () {return vm.treeid},
                selectedtimemachine: function () {return vm.selectedtimemachine},
              }
            })
          },
          tags: function (uuid, type, subtype, config) {
            $uibModal.open({
              templateUrl: 'app/pages/device/data/dialog/tags/tags.html',
              controller: 'TagsController',
              controllerAs: 'tags',
              backdrop: 'static',
              size: 'lg',
              keyboard: false,
              bindToController: true,
              resolve: {
                config: function () {return config},
                uuid: function () {return uuid},
                type: function () {return type},
                subtype: function () {return subtype},
                treeid: function () {return vm.treeid},
            }
            })
          },
          table: function (uuid, type, subtype, config) {
            $uibModal.open({
              templateUrl: 'app/pages/device/data/dialog/table/table.html',
              controller: 'TableController',
              controllerAs: 'table',
              backdrop: 'static',
              size: 'lg',
              keyboard: false,
              bindToController: true,
              resolve: {
                name: function () {return name},
                config: function () {return config},
                uuid: function () {return uuid},
                type: function () {return type},
                subtype: function () {return subtype},
                treeid: function () {return vm.treeid},
                selectedtimemachine: function () {return vm.selectedtimemachine},
              }
            })
          },
          button: function (uuid, type, subtype, config) {
            swal({
              title: `确认进行${config.name}操作吗？`,
              type: "warning",
              showCancelButton: true,
              confirmButtonColor: "#DD6B55",
              cancelButtonText: "取消",
              confirmButtonText: "确定",
              closeOnConfirm: true
            }, function () {

              $http.post(`/api/agent/device/detail/${type}/${subtype}/${vm.treeid}/${uuid}?timemachine=${vm.selectedtimemachine}`, { 'exturl': config['url'] }).success(function (data) {
                if (data.stat) {

                  $http.get(data.data).success(function (data) {
                    if (data.stat) {
                      toastr.success("操作成功！" + data.data );
                      vm.reload();
                    } else {
                      swal({ title: '操作失败', text: data.info, type: 'error' });
                    }
                  });

                } else {
                  swal({ title: '操作失败', text: data.info, type: 'error' });
                }
              });


            });
          },
          select: function (uuid, type, subtype, config, item) {
            $uibModal.open({
              templateUrl: 'app/pages/device/data/dialog/select/select.html',
              controller: 'SelectController',
              controllerAs: 'select',
              backdrop: 'static',
              size: 'lg',
              keyboard: false,
              bindToController: true,
              resolve: {
                config: function () {return config},
                uuid: function () {return uuid},
                type: function () {return type},
                subtype: function () {return subtype},
                treeid: function () {return vm.treeid},
                item: function () {return item},
                selectedtimemachine: function () {return vm.selectedtimemachine},
              }
            })
          }
        }

        vm.show = function ( uuid, type, subtype, config, item ) {
            return vm.showTypeOperate[config['type']](uuid, type, subtype, config, item)
        };

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
          templateUrl: 'app/pages/device/data/dialog/serviceTree/serviceTree.html',
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

    vm.downloadFunc = function (fileName) {
      vm.exportloadover = true
      const grepDataJSON = JSON.parse(JSON.stringify(vm.grepdata));
      const newGrepdata = {};
      angular.forEach(grepDataJSON, function (value, key) {
        if (value !== '') {
          newGrepdata[key] = value
        }
      });
      const params = { grepdata: newGrepdata, timemachine: vm.selectedtimemachine, toxlsx: 1, pageSize: '' }
      $http.post(`/api/agent/device/data/${vm.type}/${vm.subtype}/${vm.deptFilter ? 0: vm.treeid}`, params).success(function(data){
        vm.exportloadover = false
          if (data.stat){
              vm.downloadTitle = data.toxlsxtitle;
              vm.downloadData = data.data;
              if (!vm.downloadTitle) {
                vm.downloadTitle = []
              };
              const downLoadArr = [];
              vm.downloadData.forEach(item => {
                const newData = {};
                if (!vm.downloadTitle.length) {
                  downLoadArr.push(item)
                  return
                };
                vm.downloadTitle.forEach(cItem => { newData[cItem] = item[cItem] });
                downLoadArr.push(newData);
              });
              const workbook = XLSX.utils.book_new();
              const worksheet = XLSX.utils.json_to_sheet(downLoadArr);
              XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');
              const wbout = XLSX.write(workbook, { bookType: 'xlsx', type: 'array', stream: true });
              const blob = new Blob([wbout], { type: 'application/octet-stream' });
              saveAs(blob, fileName);
          }else {
            vm.downloadTitle = []
            vm.downloadData = []
              swal({ title:'获取数据失败', text: data.info, type:'error' });
          }
      });
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

      $scope.$watch(function () {return $rootScope.deptTreeNode}, function (value) {
        if (value && Object.keys(value).length !== 0) {
          vm.deptFilter = value
          vm.grepdata = {}
          angular.forEach(vm.deptFilter, function (value, key) {
            if (value !== '') {
              vm.grepdata[key] = value
            }
          });
          vm.reload()
        }
      })

      $scope.$watch(function () {return $rootScope.deptTreeId}, function (value) {
        if (value && value === 'root') {
          vm.grepdata = {}
          vm.reload()
        }
      })

      $scope.$watch(function () {return $rootScope.selectTeeName}, function (value) {
        if (value && value === 'tree') {
          vm.reload()
        }
      })
    }
})();
