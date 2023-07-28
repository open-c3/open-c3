(function(){
    'use strict';

    angular
        .module('openc3')
        .directive('cmmenu', ztree);

    /** @ngInject */
    function ztree() {
        var directive = {
            restrict: 'E',
            templateUrl: 'app/components/menu/menu.html',
            scope: {},
            controller: ZtreeController,
            controllerAs: 'tree'
        };
        return directive;

        /** @ngInject */
        function ZtreeController($injector, $stateParams, $window, $http, $state, treeService, deptTreeService, $scope, $rootScope) {

            var vm = this;
            vm.zTree = '';
            vm.isShow = false
            vm.isActive = 'tree'
            vm.isDepartment = false
            var toastr = toastr || $injector.get('toastr');
            vm.noJumpOptions = [
            'home.favorites','home.quickentry.flowline','home.quickentry.runtask','home.quickentry.cmd','home.quickentry.scp',
            'home.quickentry.approval','home.quickentry.terminal','home.quickentry.sendfile','home.quickentry.monitorkanban',
            'home.quickentry.monitorconfig','home.quickentry.monitorgroup','home.quickentry.monitornodelow','home.quickentry.monitoroncall',
            'home.quickentry.monitormailmon','home.quickentry.selfhealingconfig','home.quickentry.smallapplication',
            'home.quickentry.smallapplicationedit','home.business.job','home.business.user','home.business.file','home.business.scripts',
            'home.business.nodegroup','home.business.nodebatch','home.business.machine','home.business.notify','home.business.crontab',
            'home.business.agent','home.business.variate','home.history.jobx','home.history.job','home.history.bpm','home.history.terminal',
            'home.approval','home.myack','home.allack','home.mycase','home.allcase','home.allalerts','home.thirdparty','home.bpm','home.global.notify',
            'home.global.template','home.global.sysctl','home.global.ticket','home.global.monitortreeunbind','home.connector.config','home.connector.userinfo',
            'home.connector.userauth','home.connector.tree','home.connector.node','home.connector.mail','home.connector.mesg','home.gitreport','home.flowreport',
            'home.monreport','home.device.menu','home.device.data','home.global.k8sapptpl','home.global.jumpserverexipsite','home.connector.userleader',
            'home.history.timetask','home.business.virtual'
          ]
            // tree height auto
            angular.element('.scroller').css('height', $window.innerHeight-140);
            angular.element($window).bind('resize', function(){
                angular.element('.scroller').css('height', $window.innerHeight-140);
            });

            treeService.sync.then(function(){
                vm.zTree = $.fn.zTree.getZTreeObj('openc3tree');
                vm.focusCurrent();
                vm.zTree.setting.callback.onClick = function(event, treeId, treeNode){
                    if(treeNode.hasOwnProperty('id')){
                        if (treeNode.id == $stateParams.treeid){
                            return;
                        }
                        if (treeNode.id != 0 || treeNode.name == 'ROOT' ){
                            var sName = $state.current.name;

// sName.indexOf('home.connector.tree') !=-1
                            if(vm.noJumpOptions.includes(sName)){
                                $state.go(sName, {treeid:treeNode.id});
                            }else{
                                $state.go('home.search', {treeid:treeNode.id});
                            }

                            if( sName == 'home.kubernetesmanage' )
                            {
                                $state.go('home.kubernetesmanage', {treeid:treeNode.id,clusterid: '',namespace:'',stat:''});
                            }

                            if( sName == 'home.quickentry.flowlinedetail' )
                            {
                                $state.go('home.quickentry.flowline', {treeid:treeNode.id});
                            }

                            if( sName == 'home.gitreportfilterdata' )
                            {
                                $state.go('home.gitreport', {treeid:treeNode.id});
                            }
                            if( sName == 'home.flowreportfilterdata' )
                            {
                                $state.go('home.flowreport', {treeid:treeNode.id});
                            }
                            if( sName == 'home.monreportfilterdata' )
                            {
                                $state.go('home.monreport', {treeid:treeNode.id});
                            }
                        } else {
                            toastr.error("没有节点权限");
                        }
                    } else {
                        toastr.error("没有节点权限");
                    }
                }
            });

            // focus current node
            vm.focusCurrent = function(){
                var cNode = vm.zTree.getNodeByParam('id', $state.params.treeid);
                vm.zTree.selectNode(cNode);
                vm.zTree.expandNode(cNode);
            };

            // expand/collapse tree
            vm.expandAll = function(flag){
              if (vm.isActive === 'tree') {
                vm.zTree.expandAll(flag);
              } else if (vm.isActive === 'department') {
                vm.expandDeptAll(flag)
              }
            };

            vm.focusDeptCurrent = function () {
              var currentNode = vm.deptTree.getNodeByParam('id', $state.params.treeid);
              vm.deptTree.selectNode(currentNode);
              vm.deptTree.expandNode(currentNode);
            };
      
            vm.expandDeptAll = function (flag) {
              vm.deptTree.expandAll(flag);
            };

            vm.focusTreeCurrent = function () {
              if(vm.isActive === 'tree') {
                vm.focusCurrent()
              } else if (vm.isActive === 'department') {
                vm.focusDeptCurrent()
              }
            }

            // tree refresh
            vm.refresh = function(){
              if(vm.isActive === 'tree') {
                angular.element('.treeFresh').addClass('fa-spin');
                $http.get('/api/connector/connectorx/usertree').success(function(nodes) {
                    $.fn.zTree.init(angular.element('#openc3tree'), vm.zTree.setting, nodes.data);
                    angular.element('.treeFresh').removeClass('fa-spin');
                    vm.focusCurrent();
                });
              } else if (vm.isActive === 'department') {
                angular.element('.treeFresh').addClass('fa-spin');
                $http.get('/api/connector/connectorx/depttree').success(function(nodes) {
                  $.fn.zTree.init(angular.element('#departmentTree'), vm.deptTree.setting, nodes.data);
                  angular.element('.treeFresh').removeClass('fa-spin');
                  vm.focusDeptCurrent();
              });
              }
            };

            // 部门树
            deptTreeService.sync.then(function () {
              vm.deptTree = $.fn.zTree.getZTreeObj('departmentTree');
              vm.focusDeptCurrent();
              vm.deptTree.setting.callback.onClick = function (event, treeId, treeNode) {
                if (treeNode.hasOwnProperty('id')) {
                  const newFilter = treeNode.filter
                  $rootScope.deptTreeNode = newFilter
                  $rootScope.deptTreeId = treeNode.id
                  $scope.$apply();
                } else {
                  toastr.error("没有节点权限");
                }
              }
            })

            vm.unfold = function() {
              vm.isShow = true
              angular.element('#sidebar_left').addClass('show-unfold')
              angular.element('#content_wrapper').addClass('show-wrapper')
            }    
            vm.packUp = function() {
              vm.isShow = false
              angular.element('#sidebar_left').removeClass('show-unfold')
              angular.element('#content_wrapper').removeClass('show-wrapper')
            }

            vm.select_map = {};
            vm.search_init = function () {
              if (vm.isActive === 'tree') {
                vm.names = [];
                $http.get('/api/connector/connectorx/treemap').success(function (data) {
                  vm.name = data.data;
                  angular.forEach(vm.name, function (value) {
                    vm.names.push(value.name);
                    vm.select_map[value.name] = value.id;
                  });
                });
              } else if (vm.isActive === 'department') {
                vm.names = [];
                vm.deptArr = [vm.deptTree.getNodeByParam('id', 'root')]
                const flatArr =  flattenTree(vm.deptArr)
                vm.names = flatArr.map(item => item.name)
                angular.forEach(flatArr, function (value) {
                  vm.select_map[value.name] = value.tId;
                });
              }
            };
      
            vm.searchNode = function (item, model, label, event){
              if (vm.isActive === 'tree') {
                var node = vm.zTree.getNodeByParam("id", vm.select_map[item]);
                vm.zTree.selectNode(node);
                vm.zTree.expandNode(node);
                vm.search_init(event)
              }else if (vm.isActive === 'department') {
                var nodes = vm.deptTree.getNodeByParam("tId", vm.select_map[item]);
                vm.deptTree.selectNode(nodes);
                vm.deptTree.expandNode(nodes);
                vm.search_init(event)
                const newFilter = nodes.filter
                $rootScope.deptTreeNode = newFilter
              }
            };

            vm.handleTreeChange = function (value) {
              vm.isActive = value
              vm.select_map = {}
              $scope.selected = ''
              if (value === 'tree') {
                $rootScope.deptTreeNode = null
                var currentsNode = vm.deptTree.getNodeByParam('id', 'root');
                vm.deptTree.selectNode(currentsNode);
              }else if (value === 'department') {
                var currentNode = vm.zTree.getNodeByParam("id", $state.params.treeid);
                vm.zTree.selectNode(currentNode);
              }
            }
        
            function flattenTree(tree) {
              var result = [];
              function flatten(node) {
                result.push(node);
                if (node.children) {
                  node.children.forEach(function(child) {
                    flatten(child);
                  });
                }
              }
              tree.forEach(function(node) {
                flatten(node);
              });
              return result;
            }
            

            $scope.$watch(function () { return $state.current.name; }, function (newName) {
              if (newName === 'home.device.menu'|| newName === 'home.device.data') {
                vm.isShow = true
                vm.isDepartment = true
                angular.element('#sidebar_left').addClass('show-device-unfold')
                angular.element('#content_wrapper').addClass('show-device-wrapper')
              } else {
                vm.isShow = false
                vm.isDepartment = false
                angular.element('#sidebar_left').removeClass('show-device-unfold')
                angular.element('#content_wrapper').removeClass('show-device-wrapper')
              }
            });
        }
    }

})();
