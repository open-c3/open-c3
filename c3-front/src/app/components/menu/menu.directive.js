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
        function ZtreeController($injector, $stateParams, $window, $http, $state, treeService) {

            var vm = this;
            vm.zTree = '';
            var toastr = toastr || $injector.get('toastr');

            // tree height auto
            angular.element('.scroller').css('height', $window.innerHeight-95);
            angular.element($window).bind('resize', function(){
                angular.element('.scroller').css('height', $window.innerHeight-95);
            });

            treeService.sync.then(function(){
                vm.zTree = $.fn.zTree.getZTreeObj('openc3tree');
                vm.focusCurrent();
                vm.zTree.setting.callback.onClick = function(event, treeId, treeNode){
                    if(treeNode.hasOwnProperty('id')){
                        if (treeNode.id == $stateParams.treeid){
                            return;
                        }
                        if (treeNode.id != 0){
                            var sName = $state.current.name;

// sName.indexOf('home.connector.tree') !=-1
                            if(  
                                   sName == 'home.favorites'
                                || sName == 'home.quickentry.flowline'
                                || sName == 'home.quickentry.runtask'
                                || sName == 'home.quickentry.cmd'
                                || sName == 'home.quickentry.scp'
                                || sName == 'home.quickentry.approval'
                                || sName == 'home.quickentry.terminal'
                                || sName == 'home.quickentry.sendfile'
                                || sName == 'home.quickentry.monitorkanban'
                                || sName == 'home.quickentry.monitorconfig'
                                || sName == 'home.quickentry.monitorgroup'
                                || sName == 'home.quickentry.monitoroncall'
                                || sName == 'home.quickentry.monitormailmon'
                                || sName == 'home.quickentry.selfhealingconfig'
                                || sName == 'home.quickentry.smallapplication'
                                || sName == 'home.business.job'
                                || sName == 'home.business.user'
                                || sName == 'home.business.file'
                                || sName == 'home.business.scripts'
                                || sName == 'home.business.nodegroup'
                                || sName == 'home.business.nodebatch'
                                || sName == 'home.business.machine'
                                || sName == 'home.business.notify'
                                || sName == 'home.business.crontab'
                                || sName == 'home.business.agent'
                                || sName == 'home.business.variate'
                                || sName == 'home.history.jobx'
                                || sName == 'home.history.job'
                                || sName == 'home.history.terminal'
                                || sName == 'home.approval'
                                || sName == 'home.global.notify'
                                || sName == 'home.global.template'
                                || sName == 'home.global.ticket'
                                || sName == 'home.connector.config'
                                || sName == 'home.connector.userinfo'
                                || sName == 'home.connector.userauth'
                                || sName == 'home.connector.tree'
                                || sName == 'home.connector.node'
                                || sName == 'home.connector.mail'
                                || sName == 'home.connector.mesg'
                                || sName == 'home.gitreport'
                                || sName == 'home.flowreport'
                             ){
                                $state.go(sName, {treeid:treeNode.id});
                            }else{
                                $state.go('home.dashboard', {treeid:treeNode.id});
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
                vm.zTree.expandAll(flag);
            };

            // tree refresh
            vm.refresh = function(){
                angular.element('.treeFresh').addClass('fa-spin');
                $http.get('/api/connector/connectorx/usertree').success(function(nodes) {
                    $.fn.zTree.init(angular.element('#openc3tree'), vm.zTree.setting, nodes.data);
                    angular.element('.treeFresh').removeClass('fa-spin');
                    vm.focusCurrent();
                });
            };

            vm.select_map = {};
            vm.search_init = function () {
                vm.names = [];
                $http.get('/api/connector/connectorx/treemap').success(function (data) {
                  vm.name = data.data;
                  angular.forEach(vm.name, function (value) {
                    vm.names.push(value.name);
                    vm.select_map[value.name] = value.id;
                  });
                });
            };
      
            vm.searchNode = function (item, model, label, event){
              var node = vm.zTree.getNodeByParam("id", vm.select_map[item]);
              vm.zTree.selectNode(node);
              vm.zTree.expandNode(node);
              vm.search_init(event)
            };

        }
    }

})();
