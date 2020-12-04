(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('ShowIplistController', ShowIplistController);

    function ShowIplistController($state, $uibModal, $uibModalInstance,$http, $scope, resoureceService, groupid, $injector) {

        var vm = this;
        vm.treeid = $state.params.treeid;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        var toastr = toastr || $injector.get('toastr');

        $scope.showIPstr = [];
        if(groupid){
            $http.get('/api/jobx/group/' + vm.treeid+"/"+groupid+"/node").then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.groupData = response.data.data;
                        angular.forEach(vm.groupData, function (subip, i) {
                            var suball = [];
                            var onelen = subip.length;
                            if (onelen >0){
                                var ss = 0;
                                var group_num = 0;
                                var ipstr = [];
                                angular.forEach(subip, function (ip, n) {
                                    if (ss === 8){
                                        suball.push(ipstr.join());
                                        ss = 0;
                                        ipstr = []
                                    }
                                    ipstr.push(ip);
                                    if(onelen === n+1){
                                        suball.push(ipstr.join());
                                    }
                                    ss +=1;
                                    group_num += 1;
                                });
                                var infos = {"num": group_num, "infos": suball};
                                $scope.showIPstr.push(infos);
                            }
                        })
                    }else {
                        toastr.error( "获取项目机器信息失败:" + response.data.info )
                    }
                },
                function errorCallback (response ){
                    toastr.error( "获取项目机器信息失败:" + response.status )
                });
        }

    }
})();

