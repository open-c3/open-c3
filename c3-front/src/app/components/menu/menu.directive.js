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
            vm.isShow = false
            var toastr = toastr || $injector.get('toastr');

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
                                || sName == 'home.quickentry.monitornodelow'
                                || sName == 'home.quickentry.monitoroncall'
                                || sName == 'home.quickentry.monitormailmon'
                                || sName == 'home.quickentry.selfhealingconfig'
                                || sName == 'home.quickentry.smallapplication'
                                || sName == 'home.quickentry.smallapplicationedit'
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
                                || sName == 'home.history.bpm'
                                || sName == 'home.history.terminal'
                                || sName == 'home.approval'
                                || sName == 'home.myack'
                                || sName == 'home.allack'
                                || sName == 'home.mycase'
                                || sName == 'home.allcase'
                                || sName == 'home.allalerts'
                                || sName == 'home.thirdparty'
                                || sName == 'home.bpm'
                                || sName == 'home.global.notify'
                                || sName == 'home.global.template'
                                || sName == 'home.global.sysctl'
                                || sName == 'home.global.ticket'
                                || sName == 'home.global.monitortreeunbind'
                                || sName == 'home.connector.config'
                                || sName == 'home.connector.userinfo'
                                || sName == 'home.connector.userauth'
                                || sName == 'home.connector.tree'
                                || sName == 'home.connector.node'
                                || sName == 'home.connector.mail'
                                || sName == 'home.connector.mesg'
                                || sName == 'home.gitreport'
                                || sName == 'home.flowreport'
                                || sName == 'home.monreport'
                                || sName == 'home.device.menu'
                                || sName == 'home.device.data'
                                || sName == 'home.global.k8sapptpl'
                                || sName == 'home.global.jumpserverexipsite'
                                || sName == 'home.connector.userleader'
                                || sName == 'home.history.timetask'
                             ){
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
