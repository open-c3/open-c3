(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('TemplateController', TemplateController);

    function TemplateController( $state, $http, $scope ) {

        var vm = this;

        vm.environment = {};
        vm.reload = function () {
            vm.loadover = false
            $http.get('/api/job/environment').then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.loadover = true
                        vm.environment = response.data.data;
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

        vm.emailSave = function () {
            var emailDetail = {};
            emailDetail['notifyTemplateEmailTitle'] = vm.environment.notifyTemplateEmailTitle;
            emailDetail['notifyTemplateEmailContent'] = vm.environment.notifyTemplateEmailContent;
            vm.save( emailDetail )
        };
        vm.smsSave = function () {
            var msmDetail = {};
            msmDetail['notifyTemplateSmsContent'] = vm.environment.notifyTemplateSmsContent;
            vm.save( msmDetail )
        };


        vm.emailCiSave = function () {
            var emailDetail = {};
            emailDetail['ciTemplateEmailTitle'] = vm.environment.ciTemplateEmailTitle;
            emailDetail['ciTemplateEmailContent'] = vm.environment.ciTemplateEmailContent;
            vm.save( emailDetail )
        };
        vm.smsCiSave = function () {
            var msmDetail = {};
            msmDetail['ciTemplateSmsContent'] = vm.environment.ciTemplateSmsContent;
            vm.save( msmDetail )
        };
 
        vm.emailApprovalSave = function () {
            var emailDetail = {};
            emailDetail['approvalTemplateEmailTitle'] = vm.environment.approvalTemplateEmailTitle;
            emailDetail['approvalTemplateEmailContent'] = vm.environment.approvalTemplateEmailContent;
            vm.save( emailDetail )
        };
        vm.smsApprovalSave = function () {
            var msmDetail = {};
            msmDetail['approvalTemplateSmsContent'] = vm.environment.approvalTemplateSmsContent;
            vm.save( msmDetail )
        };
        vm.save = function (data) {
            $http.post('/api/job/environment',data).success(function(data){
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
