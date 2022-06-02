(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesEditYamlController', KubernetesEditYamlController);

    function KubernetesEditYamlController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, type, name, namespace,clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/v2/kubernetes/app/yaml?ticketid=" + ticketid + '&type=' + type + '&name=' + name + '&namespace=' + namespace  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.oldyaml = data.data;
                    vm.newyaml = data.data;
                    vm.diff();

                    vm.loadover = true;
                } else { 

                    if( data.info.indexOf("no auth") >= 0  )
                    {
                        swal({ title:'没有权限', text: "您没有该操作权限", type:'error' });
                        vm.cancel();
                        return;
                    }

                    toastr.error("加载配置失败:" + data.info)
                }
            });
        };

        vm.reload();

        vm.apply = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "type": type,
                "name": name,
                "namespace": namespace,
                "yaml": vm.newyaml,
            };
            $http.post("/api/ci/v2/kubernetes/app/apply", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.cancel();
                    swal({ title:'提交成功', text:  data.info, type:'success' });
                } else { 
                    swal({ title:'提交失败', text: "错误:" + data.info, type:'error' });
                }
            });
        };

        vm.assignment = function () {
            var postData = {
                "type": "kubernetes",
                "name": "修改Deployment配置",
                "handler": clusterinfo.create_user,
                "url": "/api/ci/v2/kubernetes/app/apply",
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name + ";\n命名空间:"+ namespace + ";\n类型:" + type + ";\n名称:" + name +";\n新配置:\n" + vm.newyaml,
                "data": {
                    "ticketid": ticketid,
                    "type": type,
                    "name": name,
                    "namespace": namespace,
                    "yaml": vm.newyaml,
                },
            };

            $uibModal.open({
                templateUrl: 'app/pages/assignment/assignmentcommit.html',
                controller: 'AssignmentCommitController',
                controllerAs: 'assignmentcommit',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    postData: function () {return postData},
                    homecancel: function () {return vm.cancel},
                }
            });
        };
//repace
       vm.replaceyaml = function()
       {
           vm.newyaml = vm.newyaml.replace( new RegExp(vm.replace1,"gm"), vm.replace2);
           vm.diff();
       }
//
        vm.oldyaml = "";
        vm.newyaml = "";

        vm.diffresultstring = "";
        vm.diff = function()
        {
            var diffresultstring = document.getElementById('diffresultstring');
            //三种diff类型，字符、单词、行 ，分别对应下面参数：diffChars  diffWords diffLines
            var diff = JsDiff["diffLines"](vm.oldyaml, vm.newyaml);

            var fragment = document.createDocumentFragment();
            for (var i=0; i < diff.length; i++) {

                if (diff[i].added && diff[i + 1] && diff[i + 1].removed) {
                    var swap = diff[i];
                    diff[i] = diff[i + 1];
                    diff[i + 1] = swap;
                }

                var node;
                if (diff[i].removed) {
                    node = document.createElement('del');
                    node.appendChild(document.createTextNode(diff[i].value));
                } else if (diff[i].added) {
                    node = document.createElement('ins');
                    node.appendChild(document.createTextNode(diff[i].value));
                } else {
                    node = document.createTextNode(diff[i].value);
                }
                fragment.appendChild(node);
            }

            diffresultstring.textContent = '';
            diffresultstring.appendChild(fragment);
        };
    }
})();
