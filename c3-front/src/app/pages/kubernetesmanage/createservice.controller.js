(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('KubernetesCreateServiceController', KubernetesCreateServiceController);

    function KubernetesCreateServiceController( $uibModalInstance, $location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $scope, $injector, ticketid, clusterinfo, namespace, name ) {

        var vm = this;

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

        $scope.editstep = 1;

        vm.loadLabels = function(ns)
        {
            $http.get("/api/ci/v2/kubernetes/util/labels/deployment?ticketid=" + ticketid + "&namespace=" + ns ).success(function(data){
                if(data.stat == true) 
                { 
                   vm.deploymentlabel = data.data;
                } else { 
                    toastr.error("加载deployment的label失败:" + data.info)
                }
            });
 
        };
        vm.namespacechange = function(ns)
        {
            vm.loadLabels(ns);
        };

        vm.tasktype = 'create';
        if( namespace && name )
        {
            vm.tasktype = 'apply';
        }

        vm.reload = function(){
            vm.loadover = false;

            var url = "/api/ci/kubernetes/data/template/service";

            if( vm.tasktype == 'apply' )
            {
                url = "/api/ci/v2/kubernetes/app/json?ticketid=" + ticketid + "&type=service&name=" + name + "&namespace=" + namespace;
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

                   $scope.selector = [];
                   if( vm.editData.spec.selector )
                   {
                       angular.forEach(vm.editData.spec.selector, function (v, k) {
                           $scope.selector.push( { "K": k, "V": v })
                       });
                   }
 
                } else { 
                    toastr.error("加载模版信息失败:" + data.info)
                }
            });

            $http.get("/api/ci/kubernetes/data/template/service_lb_annotations" ).success(function(data){
                if(data.stat == true) 
                { 
                     vm.service_lb_annotations = data.data;
                } else { 
                    toastr.error("加载service_lb_annotations模版信息失败:" + data.info)
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

                    $scope.selector = [];
                    if( vm.editData.spec.selector )
                    {
                        angular.forEach(vm.editData.spec.selector, function (v, k) {
                            $scope.selector.push( { "K": k, "V": v })
                        });
                    }

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

            if( Object.keys(annotations).length > 0 )
            {
                vm.editData.metadata.annotations = annotations;
            }
            else
            {
                delete vm.editData.metadata.annotations;
            }

//selector
            var selector = {};
            angular.forEach($scope.selector, function (v, k) {
                var key = v["K"]
                selector[key] = v["V"];
            });


            if( Object.keys(selector).length > 0 )
            {
                vm.editData.spec.selector = selector;
            }
            else
            {
                swal({ title:'错误', text: "selector不允许空", type:'error' });
                return;
            }

            if( !( vm.editData.metadata.namespace && vm.editData.metadata.name ) )
            {

                swal({ title:'错误', text: "Namespace和Name不齐全", type:'error' });
                return;
            }

            if( vm.editData.kind !== 'Service' )
            {

                swal({ title:'错误', text: "kind不正确，必须为Service", type:'error' });
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


        $scope.selector = [];

        vm.addSelector = function()
        {
            $scope.selector.push({ "K": "", "V": ""});
        }
        vm.delSelector = function(id)
        {
            $scope.selector.splice(id, 1);
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

        vm.addPorts = function()
        {
            vm.editData.spec.ports.push( angular.copy({"name": "", "port": 80, "targetPort":80, "protocol":"TCP"}));
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
                "name": "kubernetes service " + vm.tasktype,
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
