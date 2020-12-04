(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('NotifyController', NotifyController);

    /** @ngInject */
    function NotifyController( $state, $http, $scope ) {

        var vm = this;

        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/job/environment').then(
                function successCallback(response) {
                    if (response.data.stat){
                        var data_dict = response.data.data;
                         vm.loadover = true

                        angular.forEach(data_dict, function (v, k) {
                            if (v == "true"){
                                v =true
                            }else {
                                v = false;
                            }
                            $scope[k] = Boolean(v);
                        });
                    }else {
                        swal('获取信息失败', response.data.info, 'error' );
                    }
                },
                function errorCallback (response ){
                    swal('获取信息失败', response.status, 'error' );
                });
        };

        vm.checkAllEmail = function () {
            if ($scope.emailall){
                $(":checkbox").each(function () {
                    if($(this).attr("check-class") == "email"){
                        $(this).prop("checked", true);
                    }
                });
            }else {
                $(":checkbox").each(function () {
                    if($(this).attr("check-class") == "email"){
                        $(this).prop("checked", false);
                    }
                });
            }
        };

        vm.checkAllSms = function () {
            if ($scope.smsall){
                $(":checkbox").each(function () {
                    if($(this).attr("check-class") == "sms"){
                        $(this).prop("checked", true);
                    }
                });
            }else {
                $(":checkbox").each(function () {
                    if($(this).attr("check-class") == "sms"){
                        $(this).prop("checked", false);
                    }
                });
            }
        };

        vm.save = function () {
            var checked = {};
            $(":checkbox").each(function () {
                if ($(this).prop("checked")){
                    checked[$(this).attr("name")] = "true";
                }else {
                    checked[$(this).attr("name")] = "false";
                }

            });
            $http.post('/api/job/environment',checked).success(function(data){
                if (data.stat){
                    swal({ title: '保存成功', type:'success' });
                    vm.reload();
                }else {
                    swal({ title: '保存失败', text: data.info, type:'error' });
                }
            });

        };
        vm.reload()
    }

})();
