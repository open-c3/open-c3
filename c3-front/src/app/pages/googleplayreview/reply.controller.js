(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('GooglePlayReviewReplyController', GooglePlayReviewReplyController);

    function GooglePlayReviewReplyController( $state, $http, ngTableParams, $uibModalInstance, $scope, resoureceService, $injector, reload, data ) {

        var vm = this;

        var toastr = toastr || $injector.get('toastr');

        vm.data = data;
        vm.postdata = {};

        vm.replycontent = '';
        vm.cancel = function(){ $uibModalInstance.dismiss()};

        vm.showsubmit = 1;
        vm.add = function(){
            vm.showsubmit = 0;
            $http.post('/api/ci/v2/c3mc/googleplay/review/reply', { "callback": data.callback, "review_id":data.review_id, "text":vm.replycontent} ).success(function(data){
                if(data.stat == true) {
                    vm.cancel();
                    reload();
                } else {
                    vm.showsubmit = 1;
                    swal({ title: "添加失败!", text: data.info, type:'error' });
                }

            });
        };

    }
})();

