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
        vm.tableData = [];

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
            $http.post('/api/agent/device/data/' + vm.type + '/' + vm.subtype + '/' + vm.treeid, { "grepdata": vm.grepdata, "timemachine": vm.selectedtimemachine } ).success(function(data){
                if (data.stat){
                    vm.dealWithData(data.data);
                    vm.dataTable = new ngTableParams({count:25}, {counts:[],data:data.data});
                    vm.filter = data.filter;
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
    }
})();
