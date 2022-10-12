(function(){
    'use strict';

    angular
        .module('openc3')
        .controller('CopyMonitorConfigRuleController', CopyMonitorConfigRuleController);

        function CopyMonitorConfigRuleController($rootScope, $scope,$injector, $stateParams,$uibModalInstance, $window, $http, $state) {

            var vm = this;
            vm.treeid = $state.params.treeid;

            vm.cancel = function(){ $uibModalInstance.dismiss()};
            vm.zTree = '';
            var toastr = toastr || $injector.get('toastr');
            vm.cloneNodes = {};

            angular.element('.scroller').css('height', $window.innerHeight-95);
            angular.element($window).bind('resize', function(){
                angular.element('.scroller').css('height', $window.innerHeight-95);
            });
            var setting = {
                view: {
                    dblClickExpand: false,
                    showTitle:false
                }
            };

            vm.sync = $http.get('/api/connector/connectorx/usertree').success(function(nodes) {
                $.fn.zTree.init(angular.element('#openc3treeclone'), setting, nodes.data);
                vm.zTree = $.fn.zTree.getZTreeObj('openc3treeclone');
                if (vm.zTree){
                    var treeNode = vm.zTree.getNodeByParam('id', $state.params.treeid);
                    var proName = $state.current.name;
                    if (proName.indexOf('home.global') == 0 ){
                        return
                    }
                    if(treeNode == null){
                        return;
                    }
                }
                return vm.zTree;
            });


            vm.sync.then(function(){
                vm.zTree = $.fn.zTree.getZTreeObj('openc3treeclone');
                vm.focusCurrent();
                vm.zTree.setting.callback.onClick = function(event, treeId, treeNode){
                    if(treeNode.hasOwnProperty('id')){
                        if (treeNode.id != 0){
                            $scope.$apply(function () {
                                vm.cloneNodes[treeNode.id] = {"id":treeNode.id, "name":treeNode.name};
                            });

                        } else {
                            toastr.error("没有节点权限");
                        }
                    } else {
                        toastr.error("没有节点权限");
                    }
                }
            });

            vm.delNode = function (idx) {
                delete(vm.cloneNodes[idx]);
            };
            // 返回所选节点数据
            vm.saveNode = function () {
                angular.forEach(vm.cloneNodes, function (value, key) {

                    $http.post('/api/agent/monitor/config/rule/copy/' + value.id + '/' + vm.treeid ).then(
                        function successCallback(response) {
                            if (response.data.stat){
                                toastr.success( "复制成功：" + value.id );
                            }else {
                                toastr.error( "添加失败：" + response.data.info );
                            }
                        },
                        function errorCallback (response ){
                            toastr.error( "添加失败：" + response.status );
                        }
                    );

                });
                $uibModalInstance.close();

            };
            // focus current node
            vm.focusCurrent = function(){
                var cNode = vm.zTree.getNodeByParam('id', $state.params.treeid);
                vm.zTree.selectNode(cNode);
                vm.zTree.expandNode(cNode);
            };

            // expand/collapse tree
            vm.expandAll = function(flag){
                vm.zTree.expandAll(flag);
            };

            // tree refresh
            vm.refresh = function(){
                angular.element('.treeFresh').addClass('fa-spin');
                $http.get('/api/connector/connectorx/usertree').success(function(nodes) {
                    $.fn.zTree.init(angular.element('#openc3treeclone'), vm.zTree.setting, nodes.data);
                    angular.element('.treeFresh').removeClass('fa-spin');
                    vm.focusCurrent();
                });
            };
        }

})();
