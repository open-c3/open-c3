(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateSecretOpaqueController', KubernetesCreateSecretOpaqueController);

    function KubernetesCreateSecretOpaqueController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo, namespace, name, type ) {

        var vm = this;
        vm.type = type;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        $scope.editstep = 1;
       

        vm.reload = function(){
            vm.loadover = false;

            var templatetype = "null";

            if( type == 'kubernetes.io/service-account-token' )
            {
                templatetype = 'secrettoken';
            }

            if( type == 'Opaque' )
            {
                templatetype = 'secretopaque';
            }

            var url = "/api/ci/kubernetes/data/template/" + templatetype;

            if( namespace && name )
            {
                url = "/api/ci/v2/kubernetes/app/json?ticketid=" + ticketid + "&type=secret&name=" + name + "&namespace=" + namespace;
            }

            $http.get(url).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.editData = data.data;

                   $scope.labels = [];
                   if( vm.editData.metadata.labels )
                   {
                       angular.forEach(vm.editData.metadata.labels, function (v, k) {
                           $scope.labels.push( { "K": k, "V": v })
                       });
                   }


                   $scope.annotations = [];
                   if( vm.editData.metadata.annotations )
                   {
                       angular.forEach(vm.editData.metadata.annotations, function (v, k) {
                           $scope.annotations.push( { "K": k, "V": v })
                       });
                   }

                   $scope.database64 = [];
                   if( vm.editData.data )
                   {
                       angular.forEach(vm.editData.data, function (v, k) {
                           $scope.database64.push( { "K": k, "V": window.atob(v) })
                       });
                   }

 
                } else { 
                    swal({ title:'加载模版信息失败', text: data.info, type:'error' });
                    vm.cancel();
                }
            });

            $http.get("/api/ci/v2/kubernetes/namespace?ticketid=" + ticketid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.namespaces = response.data.data; 
                    }else {
                        toastr.error( "获取集群NAMESPACE数据失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取集群NAMESPACE数据失败: " + response.status )
                });
 

        };
        vm.reload();

        vm.gotostep0 = function(){
            $scope.editstep = 0; 
        };

        vm.gotostep1 = function(){
            vm.loadover = false;

            var d = {
                "data": vm.newyaml,
            };
            $http.post("/api/ci/kubernetes/data/yaml2json", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.editData = data.data

                   $scope.labels = [];
                   if( vm.editData.metadata.labels )
                   {
                       angular.forEach(vm.editData.metadata.labels, function (v, k) {
                           $scope.labels.push( { "K": k, "V": v })
                       });
                   }


                   $scope.annotations = [];
                   if( vm.editData.metadata.annotations )
                   {
                       angular.forEach(vm.editData.metadata.annotations, function (v, k) {
                           $scope.annotations.push( { "K": k, "V": v })
                       });
                   }


                   $scope.database64 = [];
                   if( vm.editData.data )
                   {
                       angular.forEach(vm.editData.data, function (v, k) {
                           $scope.database64.push( { "K": k, "V": window.atob(v) })
                       });
                   }


                    vm.loadover = true;
                    $scope.editstep = 1; 
                } else { 
                   swal({ title:'提交失败', text: data.info, type:'error' });
                }
            });

        };


        vm.toyaml = function(){
            $scope.editstep = 2; 
            var labels = {};
            angular.forEach($scope.labels, function (v, k) {
                var key = v["K"]
                labels[key] = v["V"];
            });

            vm.editData.metadata.labels = labels;


            var annotations = {};
            angular.forEach($scope.annotations, function (v, k) {
                var key = v["K"]
                annotations[key] = v["V"];
            });

            vm.editData.metadata.annotations = annotations;


            var database64 = {};
            angular.forEach($scope.database64, function (v, k) {
                var key = v["K"]
                database64[key] = window.btoa(v["V"]);
            });

            vm.editData.data = database64;

          
            var d = {
                "data": vm.editData,
            };
            $http.post("/api/ci/kubernetes/data/json2yaml", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.newyaml = data.data

                   if( vm.editData.metadata.namespace && vm.editData.metadata.name && vm.editData.kind )
                   {

                       $http.get("/api/ci/v2/kubernetes/app/yaml/always?ticketid=" + ticketid + "&type=" + vm.editData.kind + "&name=" + vm.editData.metadata.name + "&namespace=" + vm.editData.metadata.namespace ).success(function(data){
                            if(data.stat == true) 
                            { 
                               vm.oldyaml = data.data;
                               vm.diff();
                            } else { 
                                toastr.error("获取最新的配置信息失败:" + data.info)
                            }
                        });
 
                  }
                  else
                  {
                       swal({ title:'错误', text: "Namespace和Name不齐全", type:'error' });
                  }

                } else { 
                   swal({ title:'提交失败', text: data.info, type:'error' });
                }
            });



        };


        $scope.labels = [];

        vm.addLable = function()
        {
            $scope.labels.push({ "K": "", "V": ""});
        }
        vm.delLable = function(id)
        {
            $scope.labels.splice(id, 1);
        }


        $scope.annotations = [];

        vm.addAnnotations = function()
        {
            $scope.annotations.push({ "K": "", "V": ""});
        }
        vm.delAnnotations = function(id)
        {
            $scope.annotations.splice(id, 1);
        }


        $scope.database64 = [];

        vm.addDatabase64 = function()
        {
            $scope.database64.push({ "K": "", "V": ""});
        }
        vm.delDatabase64 = function(id)
        {
            $scope.database64.splice(id, 1);
        }

        vm.apply = function(){
            vm.loadover = false;
            var d = {
                "ticketid": ticketid,
                "yaml": vm.newyaml,
            };
            $http.post("/api/ci/v2/kubernetes/app/apply", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.cancel();
                   swal({ title:'提交成功', text: data.info, type:'success' });
                } else { 
                   swal({ title:'提交失败', text: data.info, type:'error' });
                }
            });
        };

        vm.assignment = function () {
            var postData = {
                "type": "kubernetes",
                "name": "kubernetes创建应用",
                "handler": clusterinfo.create_user,
                "url": "/api/ci/v2/kubernetes/app/apply",
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name +";\n配置:\n" + vm.newyaml,
                "data": {
                    "ticketid": ticketid,
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
