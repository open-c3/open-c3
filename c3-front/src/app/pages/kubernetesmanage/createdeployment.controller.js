(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateDeploymentController', KubernetesCreateDeploymentController);

    function KubernetesCreateDeploymentController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

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
            vm.yaml = demo[name];
        };


        vm.reload = function(){
            vm.loadover = false;
            $http.get("/api/ci/kubernetes/data/template/deployment" ).success(function(data){
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

        vm.toyaml = function(){
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
            vm.editData.spec.template.spec.imagePullSecrets = $scope.secrets;

            vm.editData.spec.selector.matchLabels.app = vm.editData.metadata.name;
            vm.editData.spec.template.metadata.labels.app = vm.editData.metadata.name;
            var d = {
                "data": vm.editData,
            };
            $http.post("/api/ci/kubernetes/data/json2yaml", d  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.yaml = data.data
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


        $scope.secrets = [];

        vm.addSecret = function()
        {
            $scope.secrets.push({ "name": "" });
        }
        vm.delSecret = function(id)
        {
            $scope.secrets.splice(id, 1);
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


        vm.switchStrategy = function( type ){
            vm.editData.spec.strategy.type = type;
            if( type === 'RollingUpdate' )
            {
                vm.editData.spec.strategy.rollingUpdate = { "maxUnavailable": 0, "maxSurge": 3};
            }
            else
            {
                delete vm.editData.spec.strategy.rollingUpdate;
            }
        };


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
                "yaml": vm.yaml,
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
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name +";\n配置:\n" + vm.yaml,
                "data": {
                    "ticketid": ticketid,
                    "yaml": vm.yaml,
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


    }
})();
