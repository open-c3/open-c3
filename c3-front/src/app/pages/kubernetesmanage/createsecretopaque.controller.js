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
        var demo = { };

      
        vm.demo = function( name ){
            vm.newyaml = demo[name];
        };


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
                    toastr.error("加载模版信息失败:" + data.info)
                }
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


//Secret
        vm.autoGetSecret = function()
        {
            $http.get("/api/ci/v2/kubernetes/secret?ticketid=" + ticketid + "&namespace=" + namespace ).success(function(data){
                if(data.stat == true) 
                { 
                    if( data.data.length > 0 && ! vm.editData.spec.template.spec.imagePullSecrets )
                    {
                        vm.editData.spec.template.spec.imagePullSecrets = [];
                    }
 
                    angular.forEach(data.data, function (v, k) {
                        if( v.TYPE === "kubernetes.io/dockerconfigjson" )
                        {
                            vm.editData.spec.template.spec.imagePullSecrets.push({ "name": v.NAME });
                        }
                    });

                } else { 
                    toastr.error("加载secret信息失败:" + data.info)
                }
            });
        }
        vm.addSecret = function()
        {
            if( ! vm.editData.spec.template.spec.imagePullSecrets )
            {
                vm.editData.spec.template.spec.imagePullSecrets = [];
            }
            vm.editData.spec.template.spec.imagePullSecrets.push({ "name": "" });
        }
        vm.delSecret = function(id)
        {
            vm.editData.spec.template.spec.imagePullSecrets.splice(id, 1);
        }
        vm.cleanSecret = function()
        {
            delete vm.editData.spec.template.spec.imagePullSecrets;
        }




//Command
        vm.addCommand = function(x, cmd)
        {
            if( ! x.command )
            {
                x.command = []
            }
            x.command.push(cmd)
            x.tempcommandstring = "";
        }

        vm.delCommand = function(x)
        {
            delete x.command;
            x.tempcommandstring = "";
        }


        vm.addArgs = function(x, args)
        {
            if( ! x.args )
            {
                x.args = []
            }
            x.args.push(args)
            x.tempargsstring = ""
        }

        vm.delArgs = function(x)
        {
            delete x.args;
            x.tempargsstring = ""
        }

//添加Rule的路径

        vm.addPaths = function(x)
        {
            if( ! x.http.paths )
            {
                x.http.paths = []
            }
            x.http.paths.push(angular.copy( {"pathType":"ImplementationSpecific","path":"", "backend": { "serviceName":"","servicePort":""}}));
        }
 
        vm.delPaths = function(x,id)
        {
            x.http.paths.splice(id, 1);
        }

//容器端口

        vm.addContainerPorts = function(x,protocol)
        {
            if( ! x.ports )
            {
                x.ports = []
            }
            x.ports.push({"name":"","protocol": protocol, "containerPort":""})
        }
        vm.delContainerPorts = function(x,id)
        {
            x.ports.splice(id, 1);
        }
        vm.cleanContainerPorts = function(x)
        {
            delete x.ports;
        }

//容器应用存活探针

        vm.addContainerlivenessProbeCmd = function(x)
        {
            x.livenessProbe = { "initialDelaySeconds": 30, "periodSeconds": 10, "timeoutSeconds": 5, "exec": { "command": [] }}
        }
        vm.addContainerlivenessProbeHttp = function(x)
        {
            x.livenessProbe = { "initialDelaySeconds": 30, "periodSeconds": 10, "timeoutSeconds": 5, "httpGet": { "path": "", "port": "8080", "scheme": "HTTP" }}
        }
         vm.addContainerlivenessProbePort = function(x)
        {
            x.livenessProbe = { "initialDelaySeconds": 30, "periodSeconds": 10, "timeoutSeconds": 5, "tcpSocket": { "port": "8080" }}
        }
 
        vm.cleanContainerlivenessProbe = function(x)
        {
            delete x.livenessProbe;
        }


//容器应用就绪探针

        vm.addContainerreadinessProbeCmd = function(x)
        {
            x.readinessProbe = { "initialDelaySeconds": 30, "periodSeconds": 10, "timeoutSeconds": 5, "exec": { "command": [] }}
        }
        vm.addContainerreadinessProbeHttp = function(x)
        {
            x.readinessProbe = { "initialDelaySeconds": 30, "periodSeconds": 10, "timeoutSeconds": 5, "httpGet": { "path": "", "port": "8080", "scheme": "HTTP" }}
        }
         vm.addContainerreadinessProbePort = function(x)
        {
            x.readinessProbe = { "initialDelaySeconds": 30, "periodSeconds": 10, "timeoutSeconds": 5, "tcpSocket": { "port": "8080" }}
        }
 
        vm.cleanContainerreadinessProbe = function(x)
        {
            delete x.readinessProbe;
        }



//容器数据卷
        vm.addContainerVolume = function(x)
        {
            if( ! x.volumeMounts )
            {
                x.volumeMounts = []
            }
            x.volumeMounts.push({"name":"","mountPath":""})
        }
 
        vm.addContainerVolumeFile = function(x)
        {
            if( ! x.volumeMounts )
            {
                x.volumeMounts = []
            }
            x.volumeMounts.push({"name":"","mountPath":"", "subPath": ""})
        }
 
        vm.delContainerVolume = function(x,id)
        {
            x.volumeMounts.splice(id, 1);
        }

        vm.cleanContainerVolume = function(x)
        {
            delete x.volumeMounts;
        }

//
        vm.addAnnotationsByType = function(type)
        {
            var all_ingress_lb_annotations_key = {};
            angular.forEach(vm.ingress_lb_annotations, function (v, k) {

                angular.forEach(v, function (v, k) {
                    all_ingress_lb_annotations_key[k] = 1
                });
 
            });
 

            var annotations_temp = [];
            angular.forEach($scope.annotations, function (v, k) {
                if( ! all_ingress_lb_annotations_key[v.K] )
                {
                    annotations_temp.push(v)
                }
            });
 
            $scope.annotations = annotations_temp;
 
            angular.forEach(vm.ingress_lb_annotations[type], function (v, k) {
                $scope.annotations.push({"K": k,"V":v})
            });
        }



//

        vm.addRules = function()
        {
           // var b = angular.copy(vm.containerData);
            vm.editData.spec.rules.push( angular.copy({"host": "", "http": { "paths": [] }}));
            //vm.editData.spec.template.spec.containers.push(angular.copy(vm.containerData));
            //vm.editData.spec.template.spec.containers.push(vm.containerData)
        }
 
        vm.delRules = function(id)
        {
            vm.editData.spec.rules.splice(id, 1);
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
