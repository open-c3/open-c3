(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('CopyProjectController', CopyProjectController);

    function CopyProjectController($http, $uibModalInstance, $scope, resoureceService, treeid, reload, sourceid, sourcename, $injector, $window, $state ) {

        var vm = this;
        vm.status = 0
        $scope.projectname = sourcename
        var toastr = toastr || $injector.get('toastr');


//以下是服务树
        vm.toothertree = 0;
        vm.cloneNodeId = treeid;
        vm.cloneNodeName = '';


        vm.zTree = '';

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
                            vm.cloneNodeId = treeNode.id;
                            vm.cloneNodeName = treeNode.name;
                        });

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
                $.fn.zTree.init(angular.element('#openc3treeclone'), vm.zTree.setting, nodes.data);
                angular.element('.treeFresh').removeClass('fa-spin');
                vm.focusCurrent();
            });
        };
//以上是服务树

        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.add = function(){
            var s = 0
            if ( vm.status )
            {
                s = 1
            }

            var totreeid = treeid;
            if( vm.toothertree )
            {
                totreeid = vm.cloneNodeId;
                s = 0;
            }

            $http.post('/api/ci/group/' + totreeid , { name: $scope.projectname, sourceid: sourceid, status: s } ).success(function(data){
                vm.install = { username: 'root' };
                    if(data.stat == true) {
                        var toid = data.id

                        $http.post('/api/job/jobs/' + treeid  + '/copy/byname', { fromname: '_ci_' + sourceid+'_', toname: '_ci_' + toid + '_', toprojectid: totreeid } ).success(function(data){
                            vm.install = { username: 'root' };
                                if(data.stat == true) {
                                    $http.post('/api/jobx/group/' + treeid  + '/copy/byname', { fromname: '_ci_test_' + sourceid+'_', toname: '_ci_test_' + toid + '_', toprojectid: totreeid } ).success(function(data){
                                        vm.install = { username: 'root' };
                                            if(data.stat == true) {
                                                $http.post('/api/jobx/group/' + treeid  + '/copy/byname', { fromname: '_ci_online_' + sourceid+'_', toname: '_ci_online_' + toid + '_', toprojectid: totreeid } ).success(function(data){
                                                    vm.install = { username: 'root' };
                                                        if(data.stat == true) {
                                                            vm.cancel();
                                                            reload();
                                                        } else { toastr.error( "提交失败:" + data.info ); }
                                                });
                                            } else { toastr.error( "提交失败:" + data.info ); }
                                    });
                                } else { toastr.error("提交失败:" + data.info); }
                        });
                    } else { toastr.error("提交失败:" + data.info); }
            });
        };
    }
})();

