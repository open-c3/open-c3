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

        vm.emailSet = function () {
            vm.environment.notifyTemplateEmailTitle = "作业:${name} 状态:${status}";
            vm.environment.notifyTemplateEmailContent = "服务树:${projectname}\n作业名称:${name}\n任务编号:${uuid}\n任务状态:${status}\n\n详情：" + window.location.protocol + '//' + window.location.host + "/#/history/jobdetail/${projectid}/${uuid}";
        };

        vm.emailSave = function () {
            var emailDetail = {};
            emailDetail['notifyTemplateEmailTitle'] = vm.environment.notifyTemplateEmailTitle;
            emailDetail['notifyTemplateEmailContent'] = vm.environment.notifyTemplateEmailContent;
            vm.save( emailDetail )
        };
        vm.smsSet = function () {
            vm.environment.notifyTemplateSmsContent = "服务树:${projectname}\n作业名称:${name}\n任务编号:${uuid}\n任务状态:${status}\n\n详情：" + window.location.protocol + '//' + window.location.host + "/#/history/jobdetail/${projectid}/${uuid}";
        };
        vm.smsSave = function () {
            var msmDetail = {};
            msmDetail['notifyTemplateSmsContent'] = vm.environment.notifyTemplateSmsContent;
            vm.save( msmDetail )
        };

        vm.emailCiSet = function () {
            vm.environment.ciTemplateEmailTitle = "Open-C3构建消息 项目: ${projectname} 版本:${version}";
            vm.environment.ciTemplateEmailContent = "状态: ${status}\n项目名称: ${projectname}\n代码仓库地址: ${addr}\n版本: ${version}\n触发测试环境发布: ${calltestenv}\n触发线上环境发布: ${callonlineenv}\n错误信息: ${errormsg}\n构建日志:\n${buildlog}\n\n详情:" + window.location.protocol + '//' + window.location.host + "/#/quickentry/flowlinedetail/${treeid}/${projectid}";
        };
 
        vm.emailCiSave = function () {
            var emailDetail = {};
            emailDetail['ciTemplateEmailTitle'] = vm.environment.ciTemplateEmailTitle;
            emailDetail['ciTemplateEmailContent'] = vm.environment.ciTemplateEmailContent;
            vm.save( emailDetail )
        };

        vm.smsCiSet = function () {
            vm.environment.ciTemplateSmsContent = "Open-C3构建消息\n项目:${projectname}\n版本:${version}\n状态:${status}\n\n详情:" + window.location.protocol + '//' + window.location.host + "/#/quickentry/flowlinedetail/${treeid}/${projectid}";
        };
 
        vm.smsCiSave = function () {
            var msmDetail = {};
            msmDetail['ciTemplateSmsContent'] = vm.environment.ciTemplateSmsContent;
            vm.save( msmDetail )
        };
 
        vm.emailApprovalSet = function () {
            vm.environment.approvalTemplateEmailTitle = "发布审批: ${cont}";
            vm.environment.approvalTemplateEmailContent = "审批内容: ${cont}\n\n详情:" + window.location.protocol + '//' + window.location.host + "/#/quickapproval/${uuid}";
        };

        vm.emailApprovalSave = function () {
            var emailDetail = {};
            emailDetail['approvalTemplateEmailTitle'] = vm.environment.approvalTemplateEmailTitle;
            emailDetail['approvalTemplateEmailContent'] = vm.environment.approvalTemplateEmailContent;
            vm.save( emailDetail )
        };
        vm.smsApprovalSet = function () {
            vm.environment.approvalTemplateSmsContent = "审批内容: ${cont}\n\n详情:" + window.location.protocol + '//' + window.location.host + "/#/quickapproval/${uuid}";
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
