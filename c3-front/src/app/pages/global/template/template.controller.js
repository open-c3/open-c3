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

//CI
        vm.emailCiSet = function () {
            vm.environment.ciTemplateEmailTitle = "Open-C3构建消息 项目: ${projectname} 版本:${version}";
            vm.environment.ciTemplateEmailContent = "状态: ${status}\n服务树:${treename}\n项目名称: ${projectname}\n代码仓库地址: ${addr}\n版本: ${version}\n触发测试环境发布: ${calltestenv}\n触发线上环境发布: ${callonlineenv}\n错误信息: ${errormsg}\n构建日志:\n${buildlog}\n\n详情:" + window.location.protocol + '//' + window.location.host + "/#/quickentry/flowlinedetail/${treeid}/${projectid}";
        };
 
        vm.emailCiSave = function () {
            var emailDetail = {};
            emailDetail['ciTemplateEmailTitle'] = vm.environment.ciTemplateEmailTitle;
            emailDetail['ciTemplateEmailContent'] = vm.environment.ciTemplateEmailContent;
            vm.save( emailDetail )
        };

        vm.smsCiSet = function () {
            vm.environment.ciTemplateSmsContent = "Open-C3构建消息\n服务树:${treename}\n项目:${projectname}\n版本:${version}\n状态:${status}\n\n详情:" + window.location.protocol + '//' + window.location.host + "/#/quickentry/flowlinedetail/${treeid}/${projectid}";
        };
 
        vm.smsCiSave = function () {
            var msmDetail = {};
            msmDetail['ciTemplateSmsContent'] = vm.environment.ciTemplateSmsContent;
            vm.save( msmDetail )
        };
 
//Flow
        vm.emailFlowSet = function () {
            vm.environment.flowTemplateEmailTitle = "Open-C3发布消息 项目: ${ci.name} 版本:${jobx.var.version}";
            vm.environment.flowTemplateEmailContent = "状态: ${jobx.status}\n项目名称: ${ci.name}\n代码仓库地址: ${ci.addr}\n版本: ${jobx.var.version}\n\n详情:" + window.location.protocol + '//' + window.location.host + "/#/quickentry/flowlinedetail/${ci.groupid}/${ci.id}";
        };
 
        vm.emailFlowSave = function () {
            var emailDetail = {};
            emailDetail['flowTemplateEmailTitle'] = vm.environment.flowTemplateEmailTitle;
            emailDetail['flowTemplateEmailContent'] = vm.environment.flowTemplateEmailContent;
            vm.save( emailDetail )
        };

        vm.smsFlowSet = function () {
            vm.environment.flowTemplateSmsContent = "Open-C3发布消息\n状态: ${jobx.status}\n项目名称: ${ci.name}\n代码仓库地址: ${ci.addr}\n版本: ${jobx.var.version}\n\n详情:" + window.location.protocol + '//' + window.location.host + "/#/quickentry/flowlinedetail/${ci.groupid}/${ci.id}";
        };
 
        vm.smsFlowSave = function () {
            var msmDetail = {};
            msmDetail['flowTemplateSmsContent'] = vm.environment.flowTemplateSmsContent;
            vm.save( msmDetail )
        };
 
//Approval
        vm.emailApprovalSet = function () {
            vm.environment.approvalTemplateEmailTitle = "发布审批: ${cont}";
            vm.environment.approvalTemplateEmailContent = "审批内容: ${cont}\n\n审批链接:" + window.location.protocol + '//' + window.location.host + "/#/quickapproval/${uuid}\n极速审批:" +  window.location.protocol + '//' + window.location.host + "/api/job/approval/fast/${uuid}\n";
        };

        vm.emailApprovalSave = function () {
            var emailDetail = {};
            emailDetail['approvalTemplateEmailTitle'] = vm.environment.approvalTemplateEmailTitle;
            emailDetail['approvalTemplateEmailContent'] = vm.environment.approvalTemplateEmailContent;
            vm.save( emailDetail )
        };
        vm.smsApprovalSet = function () {
            vm.environment.approvalTemplateSmsContent = "审批内容: ${cont}\n\n审批链接:" + window.location.protocol + '//' + window.location.host + "/#/quickapproval/${uuid}\n极速审批:" +  window.location.protocol + '//' + window.location.host + "/api/job/approval/fast/${uuid}\n";
        };
        vm.smsApprovalSave = function () {
            var msmDetail = {};
            msmDetail['approvalTemplateSmsContent'] = vm.environment.approvalTemplateSmsContent;
            vm.save( msmDetail )
        };
//Monitor
        vm.emailMonitorSet = function () {
            vm.environment.monitorTemplateEmailTitle   = "告警名称: ${labels.alertname} 状态：${statusZH}";
            vm.environment.monitorTemplateEmailContent = "[openc3]\n状态：${statusZH}\n当前时间: ${time}\n告警时间: ${startsAtZH}\n\n监控对象: ${instancename}\n对象别名: ${instancealias}\n\n服务树: ${treename}\n\n告警名称: ${labels.alertname}\n告警概要: ${annotations.summary}\n故障描述：\n${annotations.descriptions}\n\nACK:" + window.location.protocol + '//' + window.location.host + "/#/ack/${ack}${c3tempusertoken}";
        };

        vm.emailMonitorSave = function () {
            var emailDetail = {};
            emailDetail['monitorTemplateEmailTitle'] = vm.environment.monitorTemplateEmailTitle;
            emailDetail['monitorTemplateEmailContent'] = vm.environment.monitorTemplateEmailContent;
            vm.save( emailDetail )
        };
        vm.smsMonitorSet = function () {
            vm.environment.monitorTemplateSmsContent = "[openc3]\n状态：${statusZH}\n当前时间: ${time}\n告警时间: ${startsAtZH}\n\n监控对象: ${instancename}\n对象别名: ${instancealias}\n\n服务树: ${treename}\n\n告警名称: ${labels.alertname}\n告警概要: ${annotations.summary}\n故障描述：\n${annotations.descriptions}\n\nACK:" + window.location.protocol + '//' + window.location.host + "/#/ack/${ack}${c3tempusertoken}";
        };
        vm.smsMonitorSave = function () {
            var msmDetail = {};
            msmDetail['monitorTemplateSmsContent'] = vm.environment.monitorTemplateSmsContent;
            vm.save( msmDetail )
        };

        vm.callMonitorSet = function () {
            vm.environment.monitorTemplateCallContent = "语音告警，监控对象: ${labels.instance} ${annotations.descriptions}";
        };
        vm.callMonitorSave = function () {
            var callDetail = {};
            callDetail['monitorTemplateCallContent'] = vm.environment.monitorTemplateCallContent;
            vm.save( callDetail )
        };

//
//Mailmon
        vm.emailMailmonSet = function () {
            vm.environment.mailmonTemplateEmailTitle   = "邮件监控: ${labels.subject}";
            vm.environment.mailmonTemplateEmailContent = "账号： ${labels.account}\n内容：\n ${labels.content}\n";
        };

        vm.emailMailmonSave = function () {
            var emailDetail = {};
            emailDetail['mailmonTemplateEmailTitle'] = vm.environment.mailmonTemplateEmailTitle;
            emailDetail['mailmonTemplateEmailContent'] = vm.environment.mailmonTemplateEmailContent;
            vm.save( emailDetail )
        };
        vm.smsMailmonSet = function () {
            vm.environment.mailmonTemplateSmsContent = "账号：\n${labels.account}\n邮件标题：\n${labels.subject}\n邮件内容:\n${labels.content100}";
        };
        vm.smsMailmonSave = function () {
            var msmDetail = {};
            msmDetail['mailmonTemplateSmsContent'] = vm.environment.mailmonTemplateSmsContent;
            vm.save( msmDetail )
        };

        vm.callMailmonSet = function () {
            vm.environment.mailmonTemplateCallContent = "账号： ${labels.account}\n邮件标题：\n${labels.subject}";
        };
        vm.callMailmonSave = function () {
            var callDetail = {};
            callDetail['mailmonTemplateCallContent'] = vm.environment.mailmonTemplateCallContent;
            vm.save( callDetail )
        };

//


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
