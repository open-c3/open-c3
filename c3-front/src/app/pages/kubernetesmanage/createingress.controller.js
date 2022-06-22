(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateIngressController', KubernetesCreateIngressController);

    function KubernetesCreateIngressController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo, namespace, name ) {

        var vm = this;

        vm.annotationTypeList = [];
        if( clusterinfo.subtype === 'QCloud' )
        {
            vm.annotationTypeList = ['QCloud_ipv4','QCloud_ipv6'];
        }
        if( clusterinfo.subtype === 'AWS' )
        {
            vm.annotationTypeList = ['AWS_nlb','AWS_alb'];
        }

        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        $scope.editstep = 1;

        vm.tasktype = 'create';
        if( namespace && name )
        {
            vm.tasktype = 'apply';
        }

        vm.loadsecrets = function( ns )
        {
            $http.get("/api/ci/v2/kubernetes/secret?skip=kubernetes.io/service-account-token,kubernetes.io/dockerconfigjson&ticketid=" + ticketid + "&namespace=" + ns ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.secrets = data.data
                } else { 
                    toastr.error("加载secret信息失败:" + data.info)
                }
            });
        };

        vm.loadservices = function( ns )
        {
            $http.get("/api/ci/v2/kubernetes/service?ticketid=" + ticketid + "&namespace=" + ns ).success(function(data){
                if(data.stat == true) 
                { 
                    vm.services = data.data
                } else { 
                    toastr.error("加载service信息失败:" + data.info)
                }
            });
        };

        vm.namespacechange = function(ns)
        {
            vm.loadsecrets(ns);
            vm.loadservices(ns);
        }

        vm.reload = function(){
            vm.loadover = false;

            var url = "/api/ci/kubernetes/data/template/ingress";

            if( vm.tasktype == 'apply' )
            {
                url = "/api/ci/v2/kubernetes/app/json?ticketid=" + ticketid + "&type=ingress&name=" + name + "&namespace=" + namespace;
            }

            $http.get(url).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.editData = data.data;

                   if( namespace )
                   {
                      vm.editData.metadata.namespace = namespace;
                   }

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


                   var tlshash = {};
                   if( vm.editData.spec.tls && vm.editData.spec.tls.length > 0 )
                   {
                        angular.forEach(vm.editData.spec.tls, function (tmp, k) {
                            tlshash[tmp.hosts[0]] = tmp.secretName
                        });
                   }

                   angular.forEach(vm.editData.spec.rules, function (rule, k) {
                      if( tlshash[rule.host] )
                      {
                          rule.https_tls_temp = tlshash[rule.host]
                      }
                   });

 
                } else { 
                    toastr.error("加载信息失败:" + data.info)
                }
            });
            $http.get("/api/ci/kubernetes/data/template/ingress_lb_annotations" ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.ingress_lb_annotations = data.data;
                } else { 
                    toastr.error("加载ingress_lb_annotations模版信息失败:" + data.info)
                }
            });

            if( vm.tasktype == 'create' )
            {
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
            }

            vm.namespacechange( namespace );
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

                   var tlshash = {};
                   if( vm.editData.spec.tls && vm.editData.spec.tls.length > 0 )
                   {
                        angular.forEach(vm.editData.spec.tls, function (tmp, k) {
                            tlshash[tmp.hosts[0]] = tmp.secretName
                        });
                   }

                   angular.forEach(vm.editData.spec.rules, function (rule, k) {
                      if( tlshash[rule.host] )
                      {
                          rule.https_tls_temp = tlshash[rule.host]
                      }
                   });

                    vm.loadover = true;
                    $scope.editstep = 1; 
                } else { 
                   swal({ title:'YAML格式转换失败', text: data.info, type:'error' });
                }
            });

        };

        vm.gotostep2 = function(){
//labels
            var labels = {};
            angular.forEach($scope.labels, function (v, k) {
                var key = v["K"]
                labels[key] = v["V"];
            });

            if( Object.keys(labels).length > 0 )
            {
                vm.editData.metadata.labels = labels;
            }
            else
            {
                delete vm.editData.metadata.labels;
            }

//annotations
            var annotations = {};
            angular.forEach($scope.annotations, function (v, k) {
                var key = v["K"]
                annotations[key] = v["V"];
            });

            if( annotations['kubernetes.io/ingress.class'] === 'qcloud'  )
            {
                var annotationrulehttpx = [];
                var annotationrulehttps = [];

                if(vm.editData.apiVersion === "extensions/v1beta1" )
                {
                    angular.forEach(vm.editData.spec.rules, function (rule, k) {

                        angular.forEach(rule.http.paths, function (path, k) {
                            annotationrulehttpx.push({ "host": rule.host, "path": path.path, "backend": { "serviceName": path.backend.serviceName, "servicePort": path.backend.servicePort } });
                            if( rule.https_tls_temp )
                            {
                                annotationrulehttps.push({ "host": rule.host, "path": path.path, "backend": { "serviceName": path.backend.serviceName, "servicePort": path.backend.servicePort } });
                            }
                        });
                    });
                }

                if(vm.editData.apiVersion === "networking.k8s.io/v1" )
                {
                    angular.forEach(vm.editData.spec.rules, function (rule, k) {

                        angular.forEach(rule.http.paths, function (path, k) {
                            annotationrulehttpx.push({ "host": rule.host, "path": path.path, "backend": { "serviceName": path.backend.service.name, "servicePort": path.backend.service.port.number } });
                            if( rule.https_tls_temp )
                            {
                                annotationrulehttps.push({ "host": rule.host, "path": path.path, "backend": { "serviceName": path.backend.service.name, "servicePort": path.backend.service.port.number } });
                            }
                        });
                    });
                }
 

                if( annotationrulehttpx.length > 0 )
                {
                    annotations['kubernetes.io/ingress.http-rules'] = angular.toJson(annotationrulehttpx);
                }
                else
                {
                    delete annotations['kubernetes.io/ingress.http-rules'];
                }

                if( annotationrulehttps.length > 0 )
                {
                    annotations['kubernetes.io/ingress.https-rules'] = angular.toJson(annotationrulehttps);;
                }
                else
                {
                    delete annotations['kubernetes.io/ingress.https-rules'];
                }
            }

            if( Object.keys(annotations).length > 0 )
            {
                vm.editData.metadata.annotations = annotations;
            }
            else
            {
                delete vm.editData.metadata.annotations;
            }
//tls
            var tls = [];
            angular.forEach(vm.editData.spec.rules, function (rule, k) {
                if( rule.https_tls_temp )
                {
                    tls.push( { "hosts": [  rule.host ], "secretName": rule.https_tls_temp } )
                }
                delete rule.https_tls_temp;
            });

            if( tls.length > 0 )
            {
                vm.editData.spec.tls = tls;
            }
            else
            {
                delete vm.editData.spec.tls;
            }

            if( !( vm.editData.metadata.namespace && vm.editData.metadata.name ) )
            {

                swal({ title:'错误', text: "Namespace和Name不齐全", type:'error' });
                return;
            }

            if( vm.editData.kind !== 'Ingress' )
            {

                swal({ title:'错误', text: "kind不正确，必须为Ingress", type:'error' });
                return;
            }

            $scope.editstep = 2; 


            vm.loadover = false;
            var d = {
                "data": vm.editData,
            };
            $http.post("/api/ci/kubernetes/data/json2yaml", d  ).success(function(data){
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

        vm.addLabel = function()
        {
            $scope.labels.push({ "K": "", "V": ""});
        }
        vm.delLabel = function(id)
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

//添加Rule的路径

        vm.addPaths = function(x)
        {
            if( ! x.http.paths )
            {
                x.http.paths = []
            }

            if(vm.editData.apiVersion === "extensions/v1beta1" )
            {
                x.http.paths.push(angular.copy( {"pathType":"Prefix","path":"", "backend": { "serviceName":"","servicePort": 80 }}));
            }
            if(vm.editData.apiVersion === "networking.k8s.io/v1" )
            {
                x.http.paths.push(angular.copy( {"pathType":"Prefix","path":"", "backend": { "service": { "name": "", "port": { "number": 80 } } }}));
            }
 
        }
 
        vm.delPaths = function(x,id)
        {
            x.http.paths.splice(id, 1);
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
        vm.switchApiVersion = function( versionName ){
            vm.editData.apiVersion = versionName

            //换成新版格式
            if( versionName === 'networking.k8s.io/v1' )
            {
                if( vm.editData.spec.rules && vm.editData.spec.rules.length > 0 )
                {
                    angular.forEach(vm.editData.spec.rules, function (rule, k) {

                        if( rule.http.paths.length > 0)
                        {
                            angular.forEach(rule.http.paths, function (path, k) {
                                if( path.backend.serviceName )
                                {
                                    path.backend = { "service": { "name": path.backend.serviceName, "port": { "number": path.backend.servicePort } } };
                                }
                                else
                                {
                                    path.backend = { "service": { "name": "", "port": { "number": "" } } };
                                }
                            });
                        }
                    });
                }
            }
            //切换成旧版格式
            if( versionName === 'extensions/v1beta1' )
            {
                if( vm.editData.spec.rules && vm.editData.spec.rules.length > 0 )
                {
                    angular.forEach(vm.editData.spec.rules, function (rule, k) {

                        if( rule.http.paths.length > 0)
                        {
                            angular.forEach(rule.http.paths, function (path, k) {
                                if( path.backend.service.name )
                                {
                                    path.backend = { "serviceName": path.backend.service.name, "servicePort": path.backend.service.port.number };
                                }
                                else
                                {
                                    path.backend = { "serviceName": "", "servicePort": 80 };
                                }
                            });
                        }
                    });
                }
            }
 
        };
//

        vm.addRules = function()
        {
            vm.editData.spec.rules.push( angular.copy({"host": "", "http": { "paths": [] }}));
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
            $http.post("/api/ci/v2/kubernetes/app/" + vm.tasktype, d  ).success(function(data){
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
                "name": "kubernetes ingress" + vm.tasktype,
                "handler": clusterinfo.create_user,
                "url": "/api/ci/v2/kubernetes/app/" + vm.tasktype,
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

//
        vm.inputTodo = function(str)
        {
            var re = /XXXXX/;
            if( re.test(str) )
            {
                return 'red';
            }
            else
            {
                return 'black';
            }
        };
//
        vm.namedemoin = function()
        {
            if( vm.tasktype === 'create' && vm.editData.metadata.name === "demo" )
            {
                vm.editData.metadata.name = "";
            }
        };
        vm.namedemoout = function()
        {
            if( vm.tasktype === 'create' && (vm.editData.metadata.name == undefined || vm.editData.metadata.name == "") )
            {
                vm.editData.metadata.name = "demo";
            }
        };
        vm.describedemoin = function()
        {
            if( vm.tasktype === 'create' && vm.editData.metadata.annotations.describe === "demo" )
            {
                vm.editData.metadata.annotations.describe = "";
            }
        };
        vm.describedemoout = function()
        {
            if( vm.tasktype === 'create' && (vm.editData.metadata.annotations.describe == undefined || vm.editData.metadata.annotations.describe == "") )
            {
                vm.editData.metadata.annotations.describe = "demo";
            }
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
