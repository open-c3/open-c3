(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('MonitorKanbanController', MonitorKanbanController);

    function MonitorKanbanController($location, $anchorScroll, $state, $http, $uibModal, treeService, ngTableParams, resoureceService, $websocket, genericService, $scope, $injector, $sce ) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        var toastr = toastr || $injector.get('toastr');

        vm.dashboarnuuid1 = 'dUrNraOn1';
        vm.dashboarnuuid2 = 'dUrNraOnz';

        vm.locked = 0;
        treeService.sync.then(function(){
            vm.nodeStr = treeService.selectname();

            if( vm.locked == 1 )
            {
                return;
            }

            var xx = vm.nodeStr.split(".").length;
            if( xx <= 2 )
            {
                vm.seturl( vm.dashboarnuuid1, '_host_' );
            }
            else
            {
                vm.seturl( vm.dashboarnuuid2, '_host_' );
            }
            document.getElementById('frame_id').contentWindow.location.reload();
        });

        vm.siteaddr = window.location.protocol + '//' + window.location.host;

        vm.seturl = function( uuid, name )
        {
            if( name == '_host_' )
            {
                vm.url = vm.siteaddr + '/third-party/monitor/grafana/d/' + uuid + '/openc3-dashboard?orgId=1&var-origin_prometheus=&var-job=openc3&var-hostname=All&var-device=All&var-interval=2m&var-maxmount=&var-show_hostname=&var-total=1&var-treeid=treeid_' + vm.treeid + '&kiosk';
            }
            else
            {
                vm.url = vm.siteaddr + '/third-party/monitor/grafana/d/7h8Ok7wGz/k8sji-qun-jian-kong-kan-ban-hui-zong?orgId=1&var-datasource=thanos&var-cluster=' + name + '&var-namespace=All&var-pod=alertmanager-server-679c879455-x7vww&var-interval=$__auto_interval_interval&var-container=alertmanager&var-node=All&var-k8s_version=v1.19.6-eks-49a6c0&kiosk';
            }
        }

        vm.seturl( vm.dashboarnuuid1, '_host_' );
        vm.prometheusurl = vm.siteaddr + '/third-party/monitor/prometheus/alerts';
        vm.alertmanagerurl = vm.siteaddr + '/third-party/monitor/alertmanager/#/alerts?silenced=false&inhibited=false&active=true&filter=%7Bfromtreeid%3D"' + vm.treeid + '"%7D';
        vm.grafanaurl = vm.siteaddr + '/third-party/monitor/grafana/';

        vm.openNewWindow = function( url )
        {
            window.open( url, '_blank')
        }

        vm.trustSrc = function()
        {
            if( vm.nodeStr === undefined )
            {
                return;
            }
            return $sce.trustAsResourceUrl( vm.url );
        }

        vm.choiceKanban = '_host_';
        vm.changeKanban = function()
        {
            if( vm.choiceKanban == '_host_' )
            {
                var xx = vm.nodeStr.split(".").length;
                if( xx <= 2 )
                {
                    vm.seturl( vm.dashboarnuuid1, '_host_' );
                }
                else
                {
                    vm.seturl( vm.dashboarnuuid2, '_host_' );
                }
            }
            else
            {
                vm.url = vm.choiceKanban;
            }

            document.getElementById('frame_id').contentWindow.location.reload();
        }

        vm.reload = function(){
            vm.loadover = false;
            $http.get('/api/agent/monitor/config/kanban/' + vm.treeid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.clusterlist = response.data.data;
                        angular.forEach(response.data.data, function (value, key) {
                            if( value.default == 1 )
                            {
                                vm.locked = 1;
                                vm.choiceKanban = value.url;
                                vm.changeKanban();
                            }
                        });

                         vm.loadover = true;
                    }else {
                        toastr.error( "获取看版列表失败："+response.data.info );
                    }
                },
                function errorCallback (response){
                    toastr.error( "获取看版列表失败: " + response.status )
                });
        };

        vm.reload();

        vm.kanbanConfig = function () {
            $uibModal.open({
                templateUrl: 'app/pages/quickentry/monitorkanban/kanbanconfig.html',
                controller: 'KanbanConfigController',
                controllerAs: 'kanbanconfig',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {
                    treeid: function () {return vm.treeid},
                    homereload: function () { return vm.reload},
                }
            });
        };

    }
})();
