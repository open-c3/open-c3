(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateServiceController', KubernetesCreateServiceController);

    function KubernetesCreateServiceController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo, namespace, name ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

        $scope.editstep = 1;
var demo = {
"cm": `
apiVersion: v1
items:
- kind: ConfigMap
  apiVersion: v1
  metadata:
    name: test0
  data:
    key1: apple
- kind: ConfigMap
  apiVersion: v1
  metadata:
    name: test1
  data:
    key2: apple
kind: ConfigMapList
metadata: {}
`,

"deploy_serverside": `
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
    kubectl.kubernetes.io/last-applied-configuration: '{"kind":"Deployment","apiVersion":"apps/v1","metadata":{"name":"nginx-deployment","creationTimestamp":null,"labels":{"name":"nginx"}},"spec":{"selector":{"matchLabels":{"name":"nginx"}},"template":{"metadata":{"creationTimestamp":null,"labels":{"name":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx","resources":{}}]}},"strategy":{}},"status":{}}'
  creationTimestamp: "2016-10-24T22:15:06Z"
  generation: 6
  labels:
    name: nginx
  name: nginx-deployment
  namespace: test
  resourceVersion: "355959"
  selfLink: /apis/extensions/v1beta1/namespaces/test/deployments/nginx-deployment
  uid: 51ac266e-9a37-11e6-8738-0800270c4edc
spec:
  replicas: 1
  selector:
    matchLabels:
      name: nginx
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        name: nginx
    spec:
      containers:
      - image: nginx
        imagePullPolicy: Always
        name: nginx
        resources: {}
        terminationMessagePath: /dev/termination-log
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      securityContext: {}
      terminationGracePeriodSeconds: 30
status:
  availableReplicas: 1
  observedGeneration: 6
  replicas: 1
  updatedReplicas: 1
`,
};

      
        vm.demo = function( name ){
            vm.newyaml = demo[name];
        };


        vm.reload = function(){
            vm.loadover = false;

            var url = "/api/ci/kubernetes/data/template/service";

            if( namespace && name )
            {
                url = "/api/ci/v2/kubernetes/app/json?ticketid=" + ticketid + "&type=service&name=" + name + "&namespace=" + namespace;
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


 
                } else { 
                    toastr.error("加载模版信息失败:" + data.info)
                }
            });
//TODO 删除
            $http.get("/api/ci/kubernetes/data/template/ingress_lb_annotations" ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.service_lb_annotations = data.data;
                } else { 
                    toastr.error("加载service_lb_annotations模版信息失败:" + data.info)
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
            var all_service_lb_annotations_key = {};
            angular.forEach(vm.service_lb_annotations, function (v, k) {

                angular.forEach(v, function (v, k) {
                    all_service_lb_annotations_key[k] = 1
                });
 
            });
 

            var annotations_temp = [];
            angular.forEach($scope.annotations, function (v, k) {
                if( ! all_service_lb_annotations_key[v.K] )
                {
                    annotations_temp.push(v)
                }
            });
 
            $scope.annotations = annotations_temp;
 
            angular.forEach(vm.service_lb_annotations[type], function (v, k) {
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
                                    path.backend = { "serviceName": "", "servicePort": "" };
                                }
                            });
                        }
                    });
                }
            }
 
        };



//

        vm.addPorts = function()
        {
            vm.editData.spec.ports.push( angular.copy({"name": "", "port": "", "targetPort":"", "protocol":"TCP"}));
        }
 
        vm.delPorts = function(id)
        {
            vm.editData.spec.ports.splice(id, 1);
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
