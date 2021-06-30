(function(){
    'use strict';

    angular
        .module('openc3')
        .controller('ConnectorTreeController', ConnectorTreeController);

        function ConnectorTreeController($rootScope, $scope,$injector, $window, $http, $state) {

            var vm = this;
            vm.zTree = '';
            var toastr = toastr || $injector.get('toastr');
            vm.hideMenu = true;  //是否显示右键菜单

            // tree height auto
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
                var treedata = [ { id: 0, name: 'ROOT', children: nodes.data } ]
                $.fn.zTree.init(angular.element('#openc3treeclone'), setting, treedata);
                vm.zTree = $.fn.zTree.getZTreeObj('openc3treeclone');
                vm.zTree.expandAll(true);
                return vm.zTree;
            });


            angular.element('body').bind('mousedown',function(event){
                if (!(event.target.className == "tree-menu" || angular.element(event.target).parents(".tree-menu").length>0)) {
                    $scope.$apply(function(){
                        vm.hideMenu = true;
                    });
                }
            });

            vm.sync.then(function(){
                vm.zTree = $.fn.zTree.getZTreeObj('openc3treeclone');
                vm.focusCurrent();
                vm.zTree.setting.callback.onClick = vm.zTree.setting.callback.onRightClick = function(event, treeId, treeNode){
                    if (treeNode){
                        // 生成 xx.xx.xxx 服务树串
                        var currentN = treeNode;
                        var nodesStr = treeNode.name;
                        while(currentN.level != 0){
                            currentN = currentN.getParentNode();
                            nodesStr = currentN.name + '.' + nodesStr;
                        }
                        vm.menuTags = nodesStr;
                        vm.currentNode = treeNode;
                        vm.nodeId = treeNode.id;
                        $scope.$apply(function(){
                            // 显示菜单
                            vm.hideMenu = false;
                            // 判断是否可以 添加/删除
                            vm.canAddNode = false;
                            vm.canDelNode = false;
                            vm.canEditNode = false;
                            if (vm.currentNode.level < 5){
                                vm.canAddNode = true;
                            }
                            if (!vm.currentNode.isParent){
                                vm.canDelNode = true;
                            }
                            if (vm.nodeId < 4000000000 ){
                                vm.canEditNode = true;
                            }
 
                            //vm.canAddNode = true ? vm.currentNode.level < 2 : false;
                            //vm.canDelNode = true ? vm.currentNode.isParent == false : false;
                        });
                        // 菜单位置
                        var cx = event.clientX - 250
                        var cy = event.clientY - 50
                        angular.element('.tree-menu').css({"top":cy +'px', "left":cx+'px'});
                    }
                };
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

            // tree reload
            vm.reload = function(){
                angular.element('.treeFresh').addClass('fa-spin');
                $http.get('/api/connector/connectorx/usertree').success(function(nodes) {
                    var treedata = [ { id: 0, name: 'ROOT', children: nodes.data } ]
                    $.fn.zTree.init(angular.element('#openc3treeclone'), vm.zTree.setting, treedata);
                    angular.element('.treeFresh').removeClass('fa-spin');
                    vm.expandAll(true)
                });
            };

            // add node
            vm.addNode = function(){
                // 判断节点级别
                if (vm.currentNode.level == 5){
                    return false;
                }
                swal({
                    title: "输入节点名称",
                    text: '在 ' + vm.menuTags + ' 下添加',
                    type: "input",
                    showCancelButton: true,
                    closeOnConfirm: false,
                    animation: "slide-from-top",
                    inputPlaceholder: "new node name",
                    showLoaderOnConfirm: true
                }, function(inputValue){
                    if (inputValue === false) return false;
                    if (inputValue === "") {
                        swal.showInputError("Null!");
                        return false;
                    }
                    var newTag = vm.menuTags+'.'+inputValue;
                        var suburi = '';
                        if(vm.nodeId > 0)
                        {
                            suburi = '/' + vm.nodeId
                        }
                        $http.post('/api/connector/default/tree'+ suburi, {'name': inputValue} ).success(function(data){
                            if (data.stat){
                                swal('添加成功', '', 'success');
                                var newNode = {id:data.data, name:inputValue};
                                vm.zTree.addNodes(vm.currentNode, newNode, -1);
                            }else {
                                swal('添加失败', data.info, 'error');
                            }
                        });

                });
            };

            // del node
            vm.delNode = function(){
                swal({
                    title: "确认删除?",
                    text: '删除节点 ' + vm.menuTags,
                    type: "warning",
                    showCancelButton: true,
                    confirmButtonColor: "#DD6B55",
                    confirmButtonText: 'Delete',
                    closeOnConfirm: false,
                    showLoaderOnConfirm: true
                }, function(){

                    $http.get('/api/connector/release?id='+ vm.nodeId ).success(function(data){
                        if (data == 'true'){
                            $http.delete('/api/connector/default/tree/' + vm.nodeId ).then(function(data){
                                if (data.data.stat){
                                    swal("删除成功!", vm.menuTags, "success");
                                    vm.zTree.removeNode(vm.currentNode);
                                }else{
                                    swal("删除失败!", data.data.msg, "error");
                                }
                            },function(){
                                swal("删除失败!", vm.menuTags, "error");
                            });
                        }else {
                            swal('不允许删除', '该节点上存在资源或者配置', 'error');
                        }
                    });


                });
            };

            // rename node # TODO
            vm.renameNode = function(){
                // 判断节点级别
                if (vm.currentNode.level == 0){
                    swal("失败", "该节点不可重命名!", "error");
                    return;
                }
                var tagArr = vm.menuTags.split('.');
                swal({
                    title: "输入新名称",
                    text: tagArr[tagArr.length-1],
                    type: "input",
                    showCancelButton: true,
                    closeOnConfirm: false,
                    animation: "slide-from-top",
                    inputPlaceholder: "new node name",
                    showLoaderOnConfirm: true
                }, function(inputValue){
                    if (inputValue === false) return false;
                    if (inputValue === "") {
                        swal.showInputError("Null!");
                        return false;
                    }
                    tagArr.pop();
                    tagArr.push(inputValue);
                    var newTag = tagArr.join('.');
                    $http.post('/api/pms/api/v1/node/'+vm.currentNode.id+'/rename?name='+newTag).then(function(data){
                        if (data.data.code == 200){
                            swal("修改成功!", newTag, "success");
                            vm.currentNode.name = inputValue;
                            vm.zTree.updateNode(vm.currentNode);
                        }else{
                            swal("修改失败!", data.data.msg, "error");
                        }
                    },function(){
                        swal("修改失败!", newTag, "error");
                    });
                });
            };
        }
})();
