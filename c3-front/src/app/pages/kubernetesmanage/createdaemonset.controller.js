(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateDaemonSetController', KubernetesCreateDaemonSetController);

    function KubernetesCreateDaemonSetController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo, namespace, name ) {

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

            var url = "/api/ci/kubernetes/data/template/daemonset";

            if( namespace && name )
            {
                url = "/api/ci/v2/kubernetes/app/json?ticketid=" + ticketid + "&type=daemonset&name=" + name + "&namespace=" + namespace;
            }

            $http.get(url).success(function(data){
                if(data.stat == true) 
                { 
                   vm.loadover = true;
                   vm.editData = data.data;
                } else { 
                    toastr.error("加载模版信息失败:" + data.info)
                }
            });
            $http.get("/api/ci/kubernetes/data/template/container" ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.containerData = data.data;
                } else { 
                    toastr.error("加载container模版信息失败:" + data.info)
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

            angular.forEach(vm.editData.spec.template.spec.containers, function (v, k) {
              delete v.tempcommandstring;
              delete v.tempargsstring;
            });

            vm.editData.metadata.labels = labels;

            vm.editData.spec.selector.matchLabels.app = vm.editData.metadata.name;
            vm.editData.spec.template.metadata.labels.app = vm.editData.metadata.name;
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

        vm.addVolume = function( type )
        {
            var data = {}

            if( type === 'emptyDir' )
            {
                data = { "name": "", "emptyDir": {} }
            }

            if( type === 'hostPath' )
            {
                data = { "name": "", "hostPath": { "path": "" } }
            }

            if( type === 'nfs' )
            {
                data = { "name": "", "nfs": { "server":"", "path": "" } }
            }
            if( type === 'secret' )
            {
                data = { "name": "", "secret": { "secretName":"" } }
            }
            if( type === 'persistentVolumeClaim' )
            {
                data = { "name": "", "persistentVolumeClaim": { "claimName":"" } }
            }
            if( type === 'configMap' )
            {
                data = { "name": "", "configMap": { "name":"", "items": [ { "key": "", "path": "" } ] } }
            }



            if( ! vm.editData.spec.template.spec.volumes )
            {
                vm.editData.spec.template.spec.volumes = [];
            }

            vm.editData.spec.template.spec.volumes.push(data);
        }
         vm.delVolume = function(id)
        {
            vm.editData.spec.template.spec.volumes.splice(id, 1);
        }

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


        vm.addContainerVolume = function(x)
        {
            if( ! x.volumeMounts )
            {
                x.volumeMounts = []
            }
            x.volumeMounts.push({"name":"","mountPath":""})
        }
 
         vm.delContainerVolume = function(x,id)
        {
            x.volumeMounts.splice(id, 1);
        }



        vm.addContainer = function()
        {
            var b = angular.copy(vm.containerData);
            vm.editData.spec.template.spec.containers.push(angular.copy(vm.containerData));
            //vm.editData.spec.template.spec.containers.push(vm.containerData)
        }
 
        vm.delContainer = function(id)
        {
            vm.editData.spec.template.spec.containers.splice(id, 1);
        }



        vm.switchImagePullPolicy = function( container, type ){
            if( type ==='')
            {
                delete container['imagePullPolicy'];
            }
            else
            {
                container['imagePullPolicy'] = type;
            }
        };





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
