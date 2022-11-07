(function() {
    'use strict';

    angular
        .module('cmdb')
        .config(routerConfig);

    /** @ngInject */
    function routerConfig($stateProvider, $urlRouterProvider) {
        $stateProvider
            .state('home', {
                url: '/',
                templateUrl: 'app/main/main.html',
                controller: 'MainController',
                controllerAs: 'main'
            })
            .state('home.ttIndex', {
                url: 'ttIndex',
                templateUrl: "app/main/tt/main.html",
                controller: 'MainTTController',
                controllerAs: 'mainTT'
            })

        /** tt **/
            .state('home.tt',{
                url:'tt/',
                abstract: true,
                templateUrl: 'app/pages/tt/tt.html'
            })
            .state('home.tt.new', {
                url:'new',
                templateUrl: 'app/pages/tt/new/new.html',
                controller: 'TTNewController',
                controllerAs: 'ttnew'
            })
            .state('home.tt.show', {
                url:'show/:id',
                templateUrl: 'app/pages/tt/show/show.html',
                controller: 'TTShowController',
                controllerAs: 'ttshow'
            })
            .state('home.tt.search', {
                url:'search',
                templateUrl: 'app/pages/tt/search/search.html',
                controller: 'TTSearchController',
                controllerAs: 'ttsearch'
            })
            .state('home.tt.list', {
                url:'list?mod&g',
                templateUrl: 'app/pages/tt/list/list.html',
                controller: 'TTListController',
                controllerAs: 'ttlist'
            })

        /** group_manage **/
            .state('home.group_manage',{
                url:'group_manage/',
                abstract: true,
                templateUrl: 'app/pages/group_manage/group_manage.html'
            })
            .state('home.group_manage.my_group', {
                url:'my_group',
                templateUrl: 'app/pages/group_manage/my_group/my_group.html',
                controller: 'MyGroupController',
                controllerAs: 'mygroup'
            })

        /** report **/
            .state('home.report',{
                url:'report/',
                abstract: true,
                templateUrl: 'app/pages/report/report.html'
            })
            .state('home.report.workgroup', {
                url:'workgroup',
                templateUrl: 'app/pages/report/workgroup/workgroup.html',
                controller: 'TTReportController',
                controllerAs: 'report'
            })
            .state('home.report.cti', {
                url:'cti',
                templateUrl: 'app/pages/report/cti/cti.html',
                controller: 'TTReportController',
                controllerAs: 'report'
            })
          .state('home.report.user', {
            url:'user',
            templateUrl: 'app/pages/report/user/user.html',
            controller: 'TTReportController',
            controllerAs: 'report'
          })

        /** system **/
            .state('home.system',{
                url:'system/',
                abstract: true,
                templateUrl: 'app/pages/system/system.html'
            })
            .state('home.system.i18n', {
                url:'i18n',
                templateUrl: 'app/pages/system/i18n/i18n.html',
                controller: 'I18nController',
                controllerAs: 'i18n'
            })
            .state('home.system.impact', {
                url:'impact',
                templateUrl: 'app/pages/system/impact/impact.html',
                controller: 'ImpactController',
                controllerAs: 'impact'
            })
            .state('home.system.cti', {
                url:'cti',
                templateUrl: 'app/pages/system/cti/cti.html',
                controller: 'CtiController',
                controllerAs: 'cti'
            })
            .state('home.system.workgroup', {
                url:'workgroup',
                templateUrl: 'app/pages/system/workgroup/workgroup.html',
                controller: 'WorkgroupController',
                controllerAs: 'workgroup'
            })
            .state('home.system.email_tpl', {
                url:'email_tpl',
                templateUrl: 'app/pages/system/email_tpl/email_tpl.html',
                controller: 'EmailtplController',
                controllerAs: 'emailtpl'
            })

        /** error page **/
            .state('home.e401', {
                url:'error/401',
                templateUrl: 'app/pages/others/401.html'
            })
            .state('home.e403', {
                url:'error/403',
                templateUrl: 'app/pages/others/403.html'
            })
            .state('home.e404', {
                url:'error/404',
                templateUrl: 'app/pages/others/404.html'
            })
            .state('home.e500', {
                url:'error/500',
                templateUrl: 'app/pages/others/500.html'
            });

        $urlRouterProvider.otherwise('/');
    }

})();
