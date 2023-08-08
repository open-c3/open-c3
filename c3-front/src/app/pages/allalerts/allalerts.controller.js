(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('AllalertsController', AllalertsController);

    function AllalertsController($http, ngTableParams, $uibModal, genericService, $interval, $scope) {
        var vm = this;
        vm.seftime = genericService.seftime

        vm.siteaddr = window.location.protocol + '//' + window.location.host;
        vm.checknewstatus=false;
        vm.claimStatus = false;
        vm.alarmLevel = '';
        vm.levelOption = [
          { label: '全部级别', value: '' },
          { label: 'level1', value: 'level1' },
          { label: 'level2', value: 'level2' },
          { label: 'level3', value: 'level3', },
          { label: 'level4', value: 'level4' },
        ];

        vm.isInterval = false;

        vm.downloadTitleMap = {
          startsAt: '开始时间',
          labelsAlertname: '名称',
          labelsObj: '监控对象',
          owner: 'Owner',
          hostname: '资源别名',
          statueState: '状态',
          labelsSeverity: '告警级别',
          annotationsSummary: '概要',
          annotationsValue: '值',
          claimUuid: '认领人',
          toBindUuid: '关联工单'
        };

        vm.defaultData = []
        vm.hasDebugStatus = false;
        vm.checkDataList = [];
        vm.selectedClaims = [];
        vm.checkboxes = {
          checked: false,
          items: {},
        };

        vm.debugswitch = function() {
          vm.hasDebugStatus = !vm.hasDebugStatus
        }
        
        vm.reload = function () {
            vm.reloadB();
            vm.reloadC();
        };
        vm.reloadA = function () {
            vm.loadAover = false;
            $http.get('/api/agent/monitor/alert/0?siteaddr=' + vm.siteaddr).success(function(data){
                if (data.stat){
                    const newData = data.data.map(item => {
                      item.labelsAlertname = item.labels.alertname
                      item.labelsObj = vm.getinstancename(item.labels)
                      item.statueState = item.status.state
                      item.labelsSeverity = item.labels.severity
                      item.annotationsSummary = item.annotations.summary
                      item.annotationsValue = item.annotations.value
                      item.claimUuid = vm.dealinfo[item.uuid]
                      return item
                    })
                    vm.defaultData = newData;
                    const unCheckedData = newData.filter(item => item.status.state !== 'suppressed' && !vm.dealinfo[item.uuid])
                    vm.downloadData = unCheckedData
                    vm.checkDataList = unCheckedData
                    vm.dataTable = new ngTableParams({count:25}, {counts:[],data:unCheckedData});
                    vm.loadAover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };

        vm.tottbind = {};
        vm.reloadB = function () {
            vm.loadBover = false;
            $http.get('/api/agent/monitor/alert/tottbind/0').success(function(data){
                if (data.stat){
                    vm.tottbind = data.data;
                    vm.loadBover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };

        vm.dealinfo = {};
        vm.reloadC = function () {
            vm.loadCover = false;
            $http.get('/api/agent/monitor/ack/deal/info').success(function(data){
                if (data.stat){
                    vm.dealinfo = data.data;
                    vm.reloadA()
                    vm.loadCover = true;
                }else {
                    swal({ title:'获取列表失败', text: data.info, type:'error' });
                }
            });
        };
 
        vm.reload();

        vm.getinstancename = function( labels ) {
            var name = labels['instance'];

            if( labels['instanceid'] )
            {
                name = labels['instanceid'];
            }

            if( labels['cache_cluster_id'] )
            {
                name = labels['cache_cluster_id'];
            }

            if( labels['dbinstance_identifier'] )
            {
                name = labels['dbinstance_identifier'];
            }

            return name;
        };

        vm.loadover = true;
        vm.tott = function(d){
            swal({
                title: "提交工单",
                text: '监控告警转工单',
                type: "info",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true

            }, function(){
                vm.loadover = false;
                $http.post("/api/agent/monitor/alert/tott/0", d  ).success(function(data){
                    if(data.stat == true)
                    {
                       vm.loadover = true;
                       vm.reload();
                       swal({ title:'提交成功', text: data.info, type:'success' });
                    } else {
                       swal({ title:'提交失败', text: data.info, type:'error' });
                    }
                });

            });
        };

        vm.deal = function(d, types, selected){
            swal({
                title: `${types === 'batch' ? '批量认领告警' : '认领告警'}`,
                text: `${types === 'batch'  ? '我来批量处理这些告警' : '我来处理这个告警'}`,
                type: "info",
                showCancelButton: true,
                confirmButtonColor: "#DD6B55",
                cancelButtonText: "取消",
                confirmButtonText: "确定",
                closeOnConfirm: true

            }, function(){
                vm.loadover = false;
                const checkedUuid = types === 'batch' ? selected.join(',') : d.uuid
                $http.post("/api/agent//monitor/ack/deal/info", { "uuid": checkedUuid }  ).success(function(data){
                    if(data.stat == true)
                    {
                       vm.loadover = true;
                       vm.reloadC();
                       swal({ title:'提交成功', text: data.info, type:'success' });
                    } else {
                       swal({ title:'提交失败', text: data.info, type:'error' });
                    }
                });

            });
        };


        vm.handleBatchClaim = function () {
          vm.selectedClaims = []
          angular.forEach(vm.checkboxes.items, function (value, key) {
            if (value) vm.selectedClaims.push(key)
          })
          vm.deal({ uuid: '' }, 'batch', Array.from(new Set(vm.selectedClaims)))
        }

        vm.openTT = function (uuid, caseuuid) {
            vm.loadover = false;
            $http.get('/api/agent/monitor/alert/gotocase/0?uuid=' + uuid + '&caseuuid=' + caseuuid ).success(function(data){
                if (data.stat){
                    vm.loadover = true;
                    window.open(data.data, '_blank')
                }else {
                    swal({ title:'获取工单地址失败', text: data.info, type:'error' });
                }
            });
        };
 
        vm.openOneTab = function (url) {
            window.open(url, '_blank')
        };

        vm.handleAlarmChange = function (value) {
          vm.alarmLevel = value
          vm.handleSaveStatusChange()
        }

        // 定时任务开关
        vm.handleOpenChange = function (type) {
          swal({
            title: `${!vm.isInterval ? '开启定时刷新？' : '暂停定时刷新？'}`,
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#DD6B55",
            cancelButtonText: "取消",
            confirmButtonText: "确定",
            closeOnConfirm: true
          }, function () {
            vm.isInterval = !vm.isInterval
            let timer = $interval(function () {
              if (vm.isInterval) {
                vm.reload();
              }
            }, 15000);
            if (type === 'close') {
              $interval.cancel(timer)
            }
          });
        }

        // 保存新状态
        vm.handleSaveStatusChange = function () {
          vm.checkboxes = {
            checked: false,
            items: {},
            itemsNumber: 0
          };
          const selectData = JSON.parse(JSON.stringify(vm.defaultData))
          const checkedData = selectData.filter(item => 
            (vm.checknewstatus ? item : item.status.state !== 'suppressed') && 
            (vm.claimStatus ? item : !vm.dealinfo[item.uuid]) && 
            (vm.alarmLevel === '' ? item :  item.labels.severity === vm.alarmLevel)
          )
          vm.dataTable = new ngTableParams({count:25}, {counts:[],data:checkedData});
          vm.downloadData = checkedData
          vm.checkDataList = checkedData
        }

        // 导出函数
        vm.downloadFunc = function (fileName) {
          const downLoadArr = []
          vm.downloadData.map(item => {
            item.labelsAlertname = item.labels.alertname
            item.labelsObj = vm.getinstancename(item.labels)
            item.statueState = item.status.state
            item.labelsSeverity = item.labels.severity
            item.annotationsSummary = item.annotations.summary
            item.annotationsValue = item.annotations.value
            item.claimUuid = vm.dealinfo[item.uuid]
            item.toBindUuid = vm.tottbind[item.uuid]? vm.tottbind[item.uuid].join(','): ''
            const newData = {};
            angular.forEach(vm.downloadTitleMap, function (key, value) {
              newData[key] = item[value]
            })
            downLoadArr.push(newData)
          });
          const workbook = XLSX.utils.book_new();
          const worksheet = XLSX.utils.json_to_sheet(downLoadArr);
          XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');
          const wbout = XLSX.write(workbook, { bookType: 'xlsx', type: 'array', stream: true });
          const blob = new Blob([wbout], { type: 'application/octet-stream' });
          saveAs(blob, fileName);
        }

        // 监听全选checkbox
        $scope.$watch(function () { return vm.checkboxes.checked }, function (value) {
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
