(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesNodeController', KubernetesNodeController);

    function KubernetesNodeController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.checkboxes = {
          checked: false,
          items: {},
        }
        vm.tableData = []
        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.cordon = function(type, node,cordon){
            vm.loadover = false;
            var d = {
              "ticketid": ticketid,
              "cordon": cordon,
            }
            switch (type) {
              case 'single':
                d.node =  node;
                break
              case 'batchs':
                let nodeList = []
                for (let key in node.items) {
                  if (node.items[key] === true) {
                    nodeList.push(String(key))
                  }
                }
                switch (cordon) {
                  case 'cordon':
                    let nodeFilter = vm.tableData.filter(item => nodeList.includes(item.NAME)).filter(cItem=> !cItem.stat.SchedulingDisabled).map(item => item.NAME)
                    d.node = nodeFilter
                  break
                  case 'uncordon':
                    let unNodeFilter = vm.tableData.filter(item => nodeList.includes(item.NAME)).filter(cItem=> cItem.stat.SchedulingDisabled).map(item => item.NAME)
                    d.node = unNodeFilter
                  break
                }
                break
            }
            if (d.node.length === 0) {
              toastr.error("没有可操作的项")
              return
            }
            $http.post("/api/ci/v2/kubernetes/node/cordon", d  ).success(function(data){
                if(data.stat == true) 
                {
                    vm.loadover = true;
                    vm.reload();
                } else {
                    toastr.error("操作失败:" + data.info)
                }
            });
        };

        vm.drain = function(type, node){
            vm.loadover = false;
            var d = {
              "ticketid": ticketid,
            }
            switch (type) {
              case 'single':
                d.node =  node;
                break
              case 'batchs':
                let nodeList = []
                for (let key in node.items) {
                  nodeList.push(String(key))
                }
                d.node = nodeList
                break
            }
            if (d.node.length === 0) {
              toastr.error("没有可操作的项")
              return
            }
            $http.post("/api/ci/v2/kubernetes/node/drain", d  ).success(function(data){
                if(data.stat == true) 
                {
                    vm.loadover = true;
                    toastr.success("操作成功:" + data.info)
                    vm.reload();
                } else {
                    toastr.error("操作失败:" + data.info)
                }
            });
        };

        vm.describe = function (type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/describe.html',
                controller: 'KubernetesDescribeController',
                controllerAs: 'kubernetesdescribe',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    namespace: function () {return namespace},
                    ticketid: function () {return ticketid},
                }
            });
        };


        vm.nodetaint = function (type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/nodetaint.html',
                controller: 'KubernetesNodeTaintController',
                controllerAs: 'kubernetesnodetaint',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    namespace: function () {return namespace},
                    ticketid: function () {return ticketid},
                }
            });
        };

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/node?ticketid=" + ticketid ).success(function(data){
                vm.tableData = data.data
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.nodeTable = new ngTableParams({count:10}, {counts:[],data:data.data});
                } else { 
                    if( data.info.indexOf("no auth") >= 0  )
                    {
                        swal({ title:'没有权限', text: "您没有该操作权限", type:'error' });
                        vm.cancel();
                        return;
                    }
                    toastr.error("加载集群节点信息失败:" + data.info)
                }
            });
        };
        vm.reload();
        // 监听全选checkbox
        $scope.$watch(function () {
          return vm.checkboxes.checked;
        }, function (value) {
          angular.forEach(vm.tableData, function (item, index, array) {
            vm.checkboxes.items[[array[index].NAME]] = value
          });
          vm.checkboxes.itemsNumber = Object.keys(vm.checkboxes.items).length
          let nodeList = []
          for (let key in vm.checkboxes.items) {
            nodeList.push(String(key))
          }
        }, true);

        // 监听单个列表项的checkbox
        $scope.$watch(function () {
          return vm.checkboxes.items;
        }, function (value) {
          var checked = 0, unchecked = 0
          angular.forEach(vm.tableData, function (item, index, array) {
            checked   +=  (vm.checkboxes.items[array[index].NAME]) || 0;
            unchecked += (!vm.checkboxes.items[array[index].NAME]) || 0;
          });
          if (vm.tableData.length> 0 && ((unchecked == 0) || (checked == 0))) {
            vm.checkboxes.checked = (checked == vm.tableData.length);
          }
          vm.checkboxes.itemsNumber = checked
          angular.element(document.getElementsByClassName("select-all")).prop("indeterminate", (checked != 0 && unchecked != 0));
        }, true);

    }
})();
