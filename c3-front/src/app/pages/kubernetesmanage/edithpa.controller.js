(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesEditHpaController', KubernetesEditHpaController);

    function KubernetesEditHpaController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo, namespace, name, homereload ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

//
        vm.namespace = namespace;
        $scope.editstep = 1;
      
        vm.tasktype = 'apply';

        vm.reload = function(){
            vm.loadover = false;

            var url = "/api/ci/v2/kubernetes/app/json?ticketid=" + ticketid + "&type=hpa&name=" + name + "&namespace=" + namespace;

            $http.get(url).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.editData = data.data;

                } else { 
                    toastr.error("加载hpa配置信息失败:" + data.info)
                }
            });
        };
        vm.reload();

        vm.gotostep0 = function(){
            $scope.editstep = 0; 
        };

        vm.gotostep1 = function(){
            vm.loadover = false;

            $http.post("/api/ci/kubernetes/data/yaml2json", { "data": vm.newyaml }  ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.editData = data.data

                    vm.loadover = true;
                    $scope.editstep = 1; 
                } else { 
                   swal({ title:'YAML格式转换失败', text: data.info, type:'error' });
                }
            });

 
        };

        vm.gotostep2 = function(){

            vm.loadover = false;
            $scope.editstep = 2; 

            $http.post("/api/ci/kubernetes/data/json2yaml", { "data": vm.editData }  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.newyaml = data.data

                   $http.get("/api/ci/v2/kubernetes/app/yaml/always?ticketid=" + ticketid + "&type=" + vm.editData.kind + "&name=" + vm.editData.metadata.name + "&namespace=" + vm.editData.metadata.namespace ).success(function(data){
                        if(data.stat == true) 
                        { 
                           vm.oldyaml = data.data;
                           vm.diff();
                           vm.loadover = true;
                        } else { 
                            toastr.error("获取最新的配置信息失败:" + data.info)
                        }
                    });
 

                } else { 
                    swal({ title:'提交失败', text: data.info, type:'error' });
                }
            });

        };

        $scope.labels = [];
//
        vm.apply = function(){
            vm.loadover = false;
            vm.postyaml = vm.newyaml;
            var d = {
                "ticketid": ticketid,
                "yaml": vm.postyaml,
            };
            $http.post("/api/ci/v2/kubernetes/app/" + vm.tasktype, d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.cancel();
                   homereload();
                   swal({ title:'提交成功', text: data.info, type:'success' });
                } else { 
                   swal({ title:'提交失败', text: data.info, type:'error' });
                }
            });
        };

        vm.assignment = function () {
            vm.postyaml = vm.newyaml;

            var postData = {
                "type": "kubernetes",
                "name": "kubernetes HPA " + vm.tasktype,
                "handler": clusterinfo.create_user,
                "url": "/api/ci/v2/kubernetes/app/" + vm.tasktype,
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name + vm.postyaml,
                "data": {
                    "ticketid": ticketid,
                    "yaml": vm.postyaml,
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
