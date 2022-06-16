(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateDeploymentController', KubernetesCreateDeploymentController);

    function KubernetesCreateDeploymentController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo, namespace, name, homereload ) {

        var vm = this;

        vm.typelist = [ 'ClusterIP', 'NodePort', 'LoadBalancer', 'ExternalName' ];

        vm.annotationTypeList = [];
        if( clusterinfo.subtype === 'QCloud' )
        {
            vm.annotationTypeList = ['QCloud_lb','QCloud_ipv4','QCloud_ipv6'];
        }
        if( clusterinfo.subtype === 'AWS' )
        {
            vm.annotationTypeList = ['AWS_nlb'];
        }


        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.cancel = function(){ $uibModalInstance.dismiss(); };

        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();
        });

//service
        vm.addservice = 0;
        vm.serviceannotations = [];

        vm.serviceEditData = {
            "apiVersion": "v1",
            "kind": "Service",
            "metadata": {
                "name": "",
                "namespace": "",
                "labels": {},
                "annotations": {},
                 
            },
            "spec": {
                "clusterIP": "",
                "ports": [],
                "selector": { "app": ""},
                "type": "ClusterIP",
            }
        };

        vm.serviceAddPorts = function()
        {
            vm.serviceEditData.spec.ports.push( angular.copy({"name": "", "port": 80, "targetPort":80, "protocol":"TCP"}));
        }

        vm.serviceDelPorts = function(id)
        {
            vm.serviceEditData.spec.ports.splice(id, 1);
        }

        vm.serviceAddAnnotations = function()
        {
            vm.serviceannotations.push({ "K": "", "V": ""});
        }
        vm.serviceDelAnnotations = function(id)
        {
            vm.serviceannotations.splice(id, 1);
        }

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

        vm.serviceAddAnnotationsByType = function(type)
        {
            var all_service_lb_annotations_key = {};
            angular.forEach(vm.service_lb_annotations, function (v, k) {

                angular.forEach(v, function (v, k) {
                    all_service_lb_annotations_key[k] = 1
                });

            });

            var annotations_temp = [];
            angular.forEach(vm.serviceannotations, function (v, k) {
                if( ! all_service_lb_annotations_key[v.K] )
                {
                    annotations_temp.push(v)
                }
            });

            vm.serviceannotations = annotations_temp;

            angular.forEach(vm.service_lb_annotations[type], function (v, k) {
                vm.serviceannotations.push({"K": k,"V":v})
            });
        };

//
        vm.namespace = namespace;
        $scope.editstep = 1;
      
        vm.tasktype = 'create';
        if( namespace && name )
        {
            vm.tasktype = 'apply';
        }

        vm.reload = function(){
            vm.loadover = false;

            var url = "/api/ci/kubernetes/data/template/deployment";

            if( vm.tasktype == 'apply' )
            {
                url = "/api/ci/v2/kubernetes/app/json?ticketid=" + ticketid + "&type=deployment&name=" + name + "&namespace=" + namespace;
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

                   $scope.selectorlabels = [];
                   if( vm.editData.spec.selector && vm.editData.spec.selector.matchLabels )
                   {
                       angular.forEach(vm.editData.spec.selector.matchLabels, function (v, k) {
                           $scope.selectorlabels.push( { "K": k, "V": v })
                       });
                   }

                   $scope.nodeSelector = [];
                   if( vm.editData.spec.template.spec && vm.editData.spec.template.spec.nodeSelector )
                   {
                       angular.forEach(vm.editData.spec.template.spec.nodeSelector, function (v, k) {
                           $scope.nodeSelector.push( { "K": k, "V": v })
                       });
                   }
 
 
                } else { 
                    toastr.error("加载YAML信息失败:" + data.info)
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
//亲和性用到namespace,不管什么情况下都先加载这个列表
//            if( vm.namespace === "" )
//            {
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
//            }

            $http.get("/api/ci/v2/kubernetes/util/labels/node?ticketid=" + ticketid + "&namespace=" + vm.namespace  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.nodelabel = data.data;
                } else { 
                    toastr.error("加载node的label失败:" + data.info)
                }
            });
 
            $http.get("/api/ci/v2/kubernetes/util/labels/node_pod?ticketid=" + ticketid + "&namespace=" + vm.namespace ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.nodepodlabel = data.data;
                } else { 
                    toastr.error("加载node和pod的label失败:" + data.info)
                }
            });
 
            if( vm.tasktype === 'create' )
            {
            $http.get("/api/ci/kubernetes/data/template/service_lb_annotations" ).success(function(data){
                if(data.stat == true)
                {
                     vm.service_lb_annotations = data.data;
                } else {
                    toastr.error("加载service_lb_annotations模版信息失败:" + data.info)
                }
            });
            }
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
 
                    $scope.selectorlabels = [];
                    if( vm.editData.spec.selector && vm.editData.spec.selector.matchLabels )
                    {
                        angular.forEach(vm.editData.spec.selector.matchLabels, function (v, k) {
                            $scope.selectorlabels.push( { "K": k, "V": v })
                        });
                    }


                   $scope.nodeSelector = [];
                   if( vm.editData.spec.template.spec && vm.editData.spec.template.spec.nodeSelector )
                   {
                       angular.forEach(vm.editData.spec.template.spec.nodeSelector, function (v, k) {
                           $scope.nodeSelector.push( { "K": k, "V": v })
                       });
                   }
 
                    vm.loadover = true;
                    $scope.editstep = 1; 
                } else { 
                   swal({ title:'deployment YAML格式转换失败', text: data.info, type:'error' });
                }
            });

            if( vm.addservice === 1 )
            {
            $http.post("/api/ci/kubernetes/data/yaml2json", { "data": vm.servicenewyaml }  ).success(function(data){
                if(data.stat == true) 
                {
                    vm.serviceEditData = data.data
                    vm.serviceannotations = [];
                    if( vm.serviceEditData.metadata.annotations )
                    {
                        angular.forEach(vm.serviceEditData.metadata.annotations, function (v, k) {
                            vm.serviceannotations.push( { "K": k, "V": v })
                        });
                    }
 
                    vm.loadover = true;
                    $scope.editstep = 1; 
                } else { 
                   swal({ title:'service YAML格式转换失败', text: data.info, type:'error' });
                }
            });
            }
 
        };

        vm.switchtointmaby =  function( str )
        {
            var isnum = /^\d+$/.test(str)
            if( isnum )
            {
                return Number(str);
            }
            else
            {
                return str;
            }
        }

        vm.gotostep2 = function(){
//labels
            var labels = {};
            angular.forEach($scope.labels, function (v, k) {
                var key = v["K"]
                labels[key] = v["V"];
                if( key === "app" && vm.tasktype === "create" )
                {
                    labels[key] = vm.editData.metadata.name;
                }
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
                if( key === "app" && vm.tasktype === "create" )
                {
                    annotations[key] = vm.editData.metadata.name;
                }
            });

            if( Object.keys(annotations).length > 0 )
            {
                vm.editData.metadata.annotations = annotations;
            }
            else
            {
                delete vm.editData.metadata.annotations;
            }


//selectorlabels
            var selectorlabels = {};
            angular.forEach($scope.selectorlabels, function (v, k) {
                var key = v["K"]
                selectorlabels[key] = v["V"];
                if( key === "app" && vm.tasktype === "create" )
                {
                    selectorlabels[key] = vm.editData.metadata.name;
                }
            });

            if( Object.keys(selectorlabels).length > 0 )
            {
                vm.editData.spec.selector.matchLabels = selectorlabels;
            }
            else
            {
                delete vm.editData.spec.selector.matchLabels;
            }

            vm.editData.spec.template.metadata.labels = vm.editData.spec.selector.matchLabels;

//nodeSelector
            var nodeSelectorHash = {};
            angular.forEach($scope.nodeSelector, function (v, k) {
                var key = v["K"]
                nodeSelectorHash[key] = v["V"];
            });

            if( Object.keys(nodeSelectorHash).length > 0 )
            {
                vm.editData.spec.template.spec.nodeSelector = nodeSelectorHash;
            }
            else
            {
                delete vm.editData.spec.template.spec.nodeSelector;
            }


//clean temp data
            angular.forEach(vm.editData.spec.template.spec.containers, function (v, k) {
                 delete v.tempcommandstring;
                 delete v.tempargsstring;
            });


            if( vm.tasktype == 'create' )
            {
                vm.editData.spec.selector.matchLabels.app = vm.editData.metadata.name;
                vm.editData.spec.template.metadata.labels.app = vm.editData.metadata.name;
            }
            
            if( vm.editData.spec && vm.editData.spec.strategy && vm.editData.spec.strategy.type === 'RollingUpdate' )
            {
                vm.editData.spec.strategy.rollingUpdate.maxUnavailable = vm.switchtointmaby( vm.editData.spec.strategy.rollingUpdate.maxUnavailable );
                vm.editData.spec.strategy.rollingUpdate.maxSurge = vm.switchtointmaby( vm.editData.spec.strategy.rollingUpdate.maxSurge );
            }

            if( !( vm.editData.metadata.namespace && vm.editData.metadata.name ) )
            {
                swal({ title:'错误', text: "Namespace和Name不齐全", type:'error' });
                return;
            }

            if( vm.editData.kind !== 'Deployment' )
            {
                swal({ title:'错误', text: "kind不正确，必须为Deployment", type:'error' });
                return;
            }

//service

if( vm.addservice === 1 )
{
            var pushserviceannotations = {};
            angular.forEach(vm.serviceannotations, function (v, k) {
                 pushserviceannotations[v.K] = v.V;

            });

            vm.serviceEditData.metadata.name = vm.editData.metadata.name;
            vm.serviceEditData.metadata.namespace = vm.editData.metadata.namespace;
            vm.serviceEditData.metadata.labels = angular.copy(vm.editData.metadata.labels);
            vm.serviceEditData.metadata.annotations = pushserviceannotations;

            vm.serviceEditData.spec.selector.app = vm.editData.metadata.labels.app;
}
//service end
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

            if( vm.addservice === 1 )
            {
            $http.post("/api/ci/kubernetes/data/json2yaml", { "data": vm.serviceEditData }  ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.servicenewyaml = data.data

                   $http.get("/api/ci/v2/kubernetes/app/yaml/always?ticketid=" + ticketid + "&type=" + vm.serviceEditData.kind + "&name=" + vm.serviceEditData.metadata.name + "&namespace=" + vm.serviceEditData.metadata.namespace ).success(function(data){
                        if(data.stat == true) 
                        { 
                           vm.serviceoldyaml = data.data;
                           vm.servicediff();
//                           vm.loadover = true;
                        } else { 
                            toastr.error("获取最新的配置信息失败:" + data.info)
                        }
                    });
 

                } else { 
                    swal({ title:'提交失败', text: data.info, type:'error' });
                }
            });

            }

        };

//labels
        $scope.labels = [];
        vm.addLabel = function()
        {
            $scope.labels.push({ "K": "", "V": ""});
        }
        vm.delLabel = function(id)
        {
            $scope.labels.splice(id, 1);
        }
//annotations
        $scope.annotations = [];
        vm.addAnnotations = function()
        {
            $scope.annotations.push({ "K": "", "V": ""});
        }
        vm.delAnnotations = function(id)
        {
            $scope.annotations.splice(id, 1);
        }

//selector matchLabels
        $scope.selectorlabels = [];
        vm.addSelectorLabel = function()
        {
            $scope.selectorlabels.push({ "K": "", "V": ""});
        }
        vm.delSelectorLabel = function(id)
        {
            $scope.selectorlabels.splice(id, 1);
        }
//nodeSelector
        $scope.nodeSelector = [];
        vm.addNodeSelector = function()
        {
            $scope.nodeSelector.push({ "K": "", "V": ""});
        }
        vm.delNodeSelector = function(id)
        {
            $scope.nodeSelector.splice(id, 1);
        }


//Secret
        vm.autoGetSecret = function()
        {
            $http.get("/api/ci/v2/kubernetes/secret?ticketid=" + ticketid + "&namespace=" + vm.editData.metadata.namespace ).success(function(data){
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
        vm.addSecret = function(name)
        {
            if( ! vm.editData.spec.template.spec.imagePullSecrets )
            {
                vm.editData.spec.template.spec.imagePullSecrets = [];
            }
            vm.editData.spec.template.spec.imagePullSecrets.push({ "name": name });
        }

        vm.delSecret = function(id)
        {
            vm.editData.spec.template.spec.imagePullSecrets.splice(id, 1);
        }
        vm.cleanSecret = function()
        {
            delete vm.editData.spec.template.spec.imagePullSecrets;
        }

        vm.createSecret = function (type,name,namespace) {
            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/createsecret.html',
                controller: 'KubernetesCreateSecretController',
                controllerAs: 'kubernetescreatesecret',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    type: function () {return type},
                    name: function () {return name},
                    namespace: function () {return vm.editData.metadata.namespace},
                    ticketid: function () {return clusterinfo.id},
                    clusterinfo: function () {return clusterinfo},
                    reload: function () {return vm.addSecret },
                }
            });
        };

//NodeAffinity 节点亲和性调度
        vm.addNodeAffinity = function(type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }

            if( vm.editData.spec.template.spec.affinity === undefined || Object.keys(vm.editData.spec.template.spec.affinity).length == 0 )
            {
                vm.editData.spec.template.spec.affinity = {};
            }
            if( vm.editData.spec.template.spec.affinity.nodeAffinity === undefined || Object.keys(vm.editData.spec.template.spec.affinity.nodeAffinity).length == 0 )
            {
                vm.editData.spec.template.spec.affinity.nodeAffinity = {};
            }

            if( vm.editData.spec.template.spec.affinity.nodeAffinity[type] === undefined || Object.keys(vm.editData.spec.template.spec.affinity.nodeAffinity[type]).length == 0 )
            {
                vm.editData.spec.template.spec.affinity.nodeAffinity[type] = {};
            }

            if( vm.editData.spec.template.spec.affinity.nodeAffinity[type].nodeSelectorTerms === undefined || vm.editData.spec.template.spec.affinity.nodeAffinity[type].nodeSelectorTerms.length == 0 )
            {
                vm.editData.spec.template.spec.affinity.nodeAffinity[type].nodeSelectorTerms = [ { "matchExpressions": [ { "key": "", "operator": "In", "values": []}]} ];
            }
            else
            {
                vm.editData.spec.template.spec.affinity.nodeAffinity[type].nodeSelectorTerms[0].matchExpressions.push( { "key": "", "operator": "In", "values": [] } );
            }

        }
        vm.cleanNodeAffinity = function(type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }
 
            if( vm.editData.spec.template.spec.affinity.nodeAffinity !== undefined )
            {
                delete vm.editData.spec.template.spec.affinity.nodeAffinity[type];
            }
 
            if( vm.editData.spec.template.spec.affinity.nodeAffinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity.nodeAffinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity.nodeAffinity;
            }

            if( vm.editData.spec.template.spec.affinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity;
            }
        }
        vm.delNodeAffinity = function(id,type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }
 
            vm.editData.spec.template.spec.affinity.nodeAffinity[type].nodeSelectorTerms[0].matchExpressions.splice(id, 1);
        }

//
//NodeAffinity 节点亲和性调度
        vm.addNodeAffinityX = function(type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }

            if( vm.editData.spec.template.spec.affinity === undefined || Object.keys(vm.editData.spec.template.spec.affinity).length == 0 )
            {
                vm.editData.spec.template.spec.affinity = {};
            }
            if( vm.editData.spec.template.spec.affinity.nodeAffinity === undefined || Object.keys(vm.editData.spec.template.spec.affinity.nodeAffinity).length == 0 )
            {
                vm.editData.spec.template.spec.affinity.nodeAffinity = {};
            }

            if( vm.editData.spec.template.spec.affinity.nodeAffinity[type] === undefined || Object.keys(vm.editData.spec.template.spec.affinity.nodeAffinity[type]).length == 0 )
            {
                vm.editData.spec.template.spec.affinity.nodeAffinity[type] = [ { "weight": 100, "preference": {} }];
            }

            if( vm.editData.spec.template.spec.affinity.nodeAffinity[type][0].preference === undefined || Object.keys(vm.editData.spec.template.spec.affinity.nodeAffinity[type][0].preference).length == 0 )
            {
                vm.editData.spec.template.spec.affinity.nodeAffinity[type][0].preference = { "matchExpressions": [ { "key": "", "operator": "In", "values": []}]};
            }
            else
            {
                vm.editData.spec.template.spec.affinity.nodeAffinity[type][0].preference.matchExpressions.push( { "key": "", "operator": "In", "values": [] } );
            }

        }
        vm.cleanNodeAffinityX = function(type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }
 
            if( vm.editData.spec.template.spec.affinity.nodeAffinity !== undefined )
            {
                delete vm.editData.spec.template.spec.affinity.nodeAffinity[type];
            }
 
            if( vm.editData.spec.template.spec.affinity.nodeAffinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity.nodeAffinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity.nodeAffinity;
            }

            if( vm.editData.spec.template.spec.affinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity;
            }
        }
        vm.delNodeAffinityX = function(id,type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }
 
            vm.editData.spec.template.spec.affinity.nodeAffinity[type][0].preference.matchExpressions.splice(id, 1);
        }


//PodAffinity。POD亲和性调度
        vm.addPodAffinity = function(type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }

            if( vm.editData.spec.template.spec.affinity === undefined || Object.keys(vm.editData.spec.template.spec.affinity).length == 0 )
            {
                vm.editData.spec.template.spec.affinity = {};
            }
            if( vm.editData.spec.template.spec.affinity.podAffinity === undefined || Object.keys(vm.editData.spec.template.spec.affinity.podAffinity).length == 0 )
            {
                vm.editData.spec.template.spec.affinity.podAffinity = {};
            }

            if( vm.editData.spec.template.spec.affinity.podAffinity[type] === undefined || vm.editData.spec.template.spec.affinity.podAffinity[type].length == 0 )
            {
                vm.editData.spec.template.spec.affinity.podAffinity[type] = [ { "labelSelector": { "matchExpressions": [ { "key": "", "operator": "In", "values": [] } ] }, "namespaces": [], "topologyKey": ""} ];
            }
            else
            {
                vm.editData.spec.template.spec.affinity.podAffinity[type][0].labelSelector.matchExpressions.push( { "key": "", "operator": "In", "values": [] } );
            }

        }
        vm.cleanPodAffinity = function(type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }
            if( vm.editData.spec.template.spec.affinity.podAffinity !== undefined )
            {
                delete vm.editData.spec.template.spec.affinity.podAffinity[type];
            }
 
            if( vm.editData.spec.template.spec.affinity.podAffinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity.podAffinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity.podAffinity;
            }

            if( vm.editData.spec.template.spec.affinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity;
            }
        }
        vm.delPodAffinity = function(id,type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }
            vm.editData.spec.template.spec.affinity.podAffinity[type][0].labelSelector.matchExpressions.splice(id, 1);
        }

//PodAffinityX。POD亲和性调度
        vm.addPodAffinityX = function(type)
        {

            var tempspec = vm.editData.spec.template.spec;
            if( tempspec.affinity === undefined || Object.keys(tempspec.affinity).length == 0 )
            {
                tempspec.affinity = {};
            }
            if( tempspec.affinity.podAffinity === undefined )
            {
                tempspec.affinity.podAffinity = {};
            }

            if( tempspec.affinity.podAffinity[type] === undefined )
            {
                tempspec.affinity.podAffinity[type] = [];
            }

            if( tempspec.affinity.podAffinity[type].length == 0 )
            {
                tempspec.affinity.podAffinity[type] = [ { "weight": 100, "podAffinityTerm":  {} }];
            }

            if( tempspec.affinity.podAffinity[type][0].podAffinityTerm.labelSelector === undefined )
            {
                tempspec.affinity.podAffinity[type][0].podAffinityTerm.labelSelector = {};
            }
            if( tempspec.affinity.podAffinity[type][0].podAffinityTerm.namespaces === undefined )
            {
                tempspec.affinity.podAffinity[type][0].podAffinityTerm.namespaces = [];
            }

            if( tempspec.affinity.podAffinity[type][0].podAffinityTerm.topologyKey === undefined )
            {
                tempspec.affinity.podAffinity[type][0].podAffinityTerm.topologyKey = "";
            }

            if( tempspec.affinity.podAffinity[type][0].podAffinityTerm.labelSelector.matchExpressions === undefined )
            {
                tempspec.affinity.podAffinity[type][0].podAffinityTerm.labelSelector.matchExpressions = [];
            }

            tempspec.affinity.podAffinity[type][0].podAffinityTerm.labelSelector.matchExpressions.push( { "key": "", "operator": "In", "values": [] } );

        }
        vm.cleanPodAffinityX = function(type)
        {
            if( vm.editData.spec.template.spec.affinity.podAffinity !== undefined )
            {
                delete vm.editData.spec.template.spec.affinity.podAffinity[type];
            }
 
            if( vm.editData.spec.template.spec.affinity.podAffinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity.podAffinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity.podAffinity;
            }

            if( vm.editData.spec.template.spec.affinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity;
            }
        }
        vm.delPodAffinityX = function(id,type)
        {
            vm.editData.spec.template.spec.affinity.podAffinity[type][0].podAffinityTerm.labelSelector.matchExpressions.splice(id, 1);
        }


//PodAntiAffinity  POD 反亲和性调度
        vm.addPodAntiAffinity = function(type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }
            if( vm.editData.spec.template.spec.affinity === undefined || Object.keys(vm.editData.spec.template.spec.affinity).length == 0 )
            {
                vm.editData.spec.template.spec.affinity = {};
            }
            if( vm.editData.spec.template.spec.affinity.podAntiAffinity === undefined || Object.keys(vm.editData.spec.template.spec.affinity.podAntiAffinity).length == 0 )
            {
                vm.editData.spec.template.spec.affinity.podAntiAffinity = {};
            }

            if( vm.editData.spec.template.spec.affinity.podAntiAffinity[type] === undefined || vm.editData.spec.template.spec.affinity.podAntiAffinity[type].length == 0 )
            {
                vm.editData.spec.template.spec.affinity.podAntiAffinity[type] = [ { "labelSelector": { "matchExpressions": [ { "key": "", "operator": "In", "values": [] } ] }, "namespaces": [], "topologyKey": ""} ];
            }
            else
            {
                vm.editData.spec.template.spec.affinity.podAntiAffinity[type][0].labelSelector.matchExpressions.push( { "key": "", "operator": "In", "values": [] } );
            }

        }
        vm.cleanPodAntiAffinity = function(type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }
            if( vm.editData.spec.template.spec.affinity.podAntiAffinity !== undefined )
            {
                delete vm.editData.spec.template.spec.affinity.podAntiAffinity[type];
            }
 
            if( vm.editData.spec.template.spec.affinity.podAntiAffinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity.podAntiAffinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity.podAntiAffinity;
            }

            if( vm.editData.spec.template.spec.affinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity;
            }
        }
        vm.delPodAntiAffinity = function(id,type)
        {
            if( type == undefined ) { type = 'requiredDuringSchedulingIgnoredDuringExecution'; }
            vm.editData.spec.template.spec.affinity.podAntiAffinity[type][0].labelSelector.matchExpressions.splice(id, 1);
        }

//PodAntiAffinity  POD 反亲和性调度
        vm.addPodAntiAffinityX = function(type)
        {
            var tempspec = vm.editData.spec.template.spec;
            if( tempspec.affinity === undefined || Object.keys(tempspec.affinity).length == 0 )
            {
                tempspec.affinity = {};
            }
            if( tempspec.affinity.podAntiAffinity === undefined )
            {
                tempspec.affinity.podAntiAffinity = {};
            }

            if( tempspec.affinity.podAntiAffinity[type] === undefined )
            {
                tempspec.affinity.podAntiAffinity[type] = [];
            }

            if( tempspec.affinity.podAntiAffinity[type].length == 0 )
            {
                tempspec.affinity.podAntiAffinity[type] = [ { "weight": 100, "podAffinityTerm":  {} }];
            }

            if( tempspec.affinity.podAntiAffinity[type][0].podAffinityTerm.labelSelector === undefined )
            {
                tempspec.affinity.podAntiAffinity[type][0].podAffinityTerm.labelSelector = {};
            }
            if( tempspec.affinity.podAntiAffinity[type][0].podAffinityTerm.namespaces === undefined )
            {
                tempspec.affinity.podAntiAffinity[type][0].podAffinityTerm.namespaces = [];
            }

            if( tempspec.affinity.podAntiAffinity[type][0].podAffinityTerm.topologyKey === undefined )
            {
                tempspec.affinity.podAntiAffinity[type][0].podAffinityTerm.topologyKey = "";
            }

            if( tempspec.affinity.podAntiAffinity[type][0].podAffinityTerm.labelSelector.matchExpressions === undefined )
            {
                tempspec.affinity.podAntiAffinity[type][0].podAffinityTerm.labelSelector.matchExpressions = [];
            }

            tempspec.affinity.podAntiAffinity[type][0].podAffinityTerm.labelSelector.matchExpressions.push( { "key": "", "operator": "In", "values": [] } );

        }
        vm.cleanPodAntiAffinityX = function(type)
        {
            if( vm.editData.spec.template.spec.affinity.podAntiAffinity !== undefined )
            {
                delete vm.editData.spec.template.spec.affinity.podAntiAffinity[type];
            }
 
            if( vm.editData.spec.template.spec.affinity.podAntiAffinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity.podAntiAffinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity.podAntiAffinity;
            }

            if( vm.editData.spec.template.spec.affinity !== undefined && Object.keys(vm.editData.spec.template.spec.affinity).length == 0 )
            {
                delete vm.editData.spec.template.spec.affinity;
            }
 
        }
        vm.delPodAntiAffinityX = function(id,type)
        {
            vm.editData.spec.template.spec.affinity.podAntiAffinity[type][0].labelSelector.matchExpressions.splice(id, 1);
        }

//tolerations 容忍/调度
        vm.addTolerations = function()
        {
            if( vm.editData.spec.template.spec.tolerations === undefined || vm.editData.spec.template.spec.tolerations.length == 0 )
            {
                vm.editData.spec.template.spec.tolerations = [];
            }
            vm.editData.spec.template.spec.tolerations.push( { "key": "", "operator": "Equal", "value": "", "effect": "NoSchedule" } );
        }
        vm.cleanTolerations = function()
        {
            delete vm.editData.spec.template.spec.tolerations;
        }
        vm.delTolerations = function(id)
        {
            vm.editData.spec.template.spec.tolerations.splice(id, 1);
        }

//Volume
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
                data = { "name": "", "configMap": { "name":"" } }
                //data = { "name": "", "configMap": { "name":"", "items": [ { "key": "", "path": "" } ] } }
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
        vm.cleanVolume = function()
        {
            delete vm.editData.spec.template.spec.volumes;
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
//Args
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

//容器环境变量
        vm.addContainerEnv = function(x)
        {
            if( ! x.env )
            {
                x.env = []
            }
            x.env.push({"name":"","value":""})
        }
 
        vm.addContainerEnvConfigMap = function(x)
        {
            if( ! x.env )
            {
                x.env = []
            }
            x.env.push({"name": "", "valueFrom": { "configMapKeyRef": { "name": "", "key": "" } }})
        }
        vm.addContainerEnvSecret = function(x)
        {
            if( ! x.env )
            {
                x.env = []
            }
            x.env.push({"name": "", "valueFrom": { "secretKeyRef": { "name": "", "key": "" } }})
        }
 
        vm.addContainerEnvField = function(x)
        {
            if( ! x.env )
            {
                x.env = []
            }
            x.env.push({"name": "", "valueFrom": { "fieldRef": { "fieldPath": "" } }})
        }
 
        vm.delContainerEnv = function(x,id)
        {
            x.env.splice(id, 1);
        }
        vm.cleanContainerEnv = function(x)
        {
            delete x.env;
        }

//容器端口
        vm.addContainerPorts = function(x,protocol)
        {
            if( ! x.ports )
            {
                x.ports = []
            }
            x.ports.push({"name":"","protocol": protocol, "containerPort":80})
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
            x.livenessProbe = { "initialDelaySeconds": 30, "periodSeconds": 10, "timeoutSeconds": 5, "httpGet": { "path": "", "port": 8080, "scheme": "HTTP" }}
        }
         vm.addContainerlivenessProbePort = function(x)
        {
            x.livenessProbe = { "initialDelaySeconds": 30, "periodSeconds": 10, "timeoutSeconds": 5, "tcpSocket": { "port": 8080 }}
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
            x.readinessProbe = { "initialDelaySeconds": 30, "periodSeconds": 10, "timeoutSeconds": 5, "httpGet": { "path": "", "port": 8080, "scheme": "HTTP" }}
        }
         vm.addContainerreadinessProbePort = function(x)
        {
            x.readinessProbe = { "initialDelaySeconds": 30, "periodSeconds": 10, "timeoutSeconds": 5, "tcpSocket": { "port": 8080 }}
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
        vm.addContainer = function()
        {
            var b = angular.copy(vm.containerData);
            vm.editData.spec.template.spec.containers.push(angular.copy(vm.containerData));
        }
 
        vm.delContainer = function(id)
        {
            vm.editData.spec.template.spec.containers.splice(id, 1);
        }

//
        vm.switchStrategy = function( type ){
            if( ! vm.editData.spec.strategy )
            {
                vm.editData.spec.strategy = {};
            }
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

//
        vm.addImageAddrByTicket = function (container) {
            vm.addImageAddrByTicket_set = function(repo) {
                container.image = repo
            }

            $uibModal.open({
                templateUrl: 'app/pages/kubernetesmanage/harborimage.html',
                controller: 'KubernetesHarborImageController',
                controllerAs: 'kubernetesharborimage',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    ticketid: function () {return ''},
                    homereload: function () {return vm.addImageAddrByTicket_set},
                }
            });
        };

        vm.apply = function(){
            vm.loadover = false;
            vm.postyaml = vm.newyaml;

            if( vm.addservice === 1 )
            {
                vm.postyaml = vm.newyaml + "\n---\n" + vm.servicenewyaml;
            }
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

            if( vm.addservice === 1 )
            {
                vm.postyaml = vm.newyaml + "\n---\n" + vm.servicenewyaml;
            }
 
            var postData = {
                "type": "kubernetes",
                "name": "kubernetes deployment " + vm.tasktype,
                "handler": clusterinfo.create_user,
                "url": "/api/ci/v2/kubernetes/app/" + vm.tasktype,
                "method": "POST",
                "submit_reason": "",
                "remarks": "\n集群ID:" + ticketid + ";\n集群名称:" + clusterinfo.name +";\n配置:\n" + vm.postyaml,
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

//repace
       vm.replaceyaml = function()
       {
           vm.newyaml = vm.newyaml.replace( new RegExp(vm.replace1,"gm"), vm.replace2);
           vm.diff();
       }
//service
        vm.serviceoldyaml = "";
        vm.servicenewyaml = "";
        vm.servicediffresultstring = "";
        vm.servicediff = function()
        {
            var servicediffresultstring = document.getElementById('servicediffresultstring');
            //三种diff类型，字符、单词、行 ，分别对应下面参数：diffChars  diffWords diffLines
            var diff = JsDiff["diffLines"](vm.serviceoldyaml, vm.servicenewyaml);

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

            servicediffresultstring.textContent = '';
            servicediffresultstring.appendChild(fragment);
        };

    }
})();
