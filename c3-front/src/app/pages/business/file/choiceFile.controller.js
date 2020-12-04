(function () {
    'use strict';
    angular
        .module('openc3')
        .controller('ChoiceFileController', ChoiceFileController);

    function ChoiceFileController($uibModalInstance,$uibModal,$timeout,$state, $http, $scope, ngTableParams, resoureceService, $injector) {

        var vm = this;
        var toastr = toastr || $injector.get('toastr');
        $scope.choiceType = 'choice';      
        $scope.selected = [];
        $scope.radioselected = {};
        $scope.selectedData = [];
        $scope.allData = [];
        $scope.s_file = '';
        $scope.inputFileName = '';
        vm.inputFileName = $scope.inputFileName;
        vm.treeid = $state.params.treeid;
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.getFiles = function () {
            $http.get('/api/job/fileserver/'+ vm.treeid).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.files_Table = new ngTableParams({count:15}, {counts:[],data:response.data.data.reverse()});
                    }else {
                        toastr.error( "获取文件信息失败："+response.data.info )
                    }
                },
                function errorCallback (response ){
                    toastr.error( "获取文件信息失败："+response.status )
                });
        };

        vm.deleteFile = function (idx) {
            resoureceService.file.delete([vm.treeid, idx], null, null)
                .then(function (repo) {
                    if (repo.stat){
                        vm.getFiles();
                    }
                    else
                    {
                        toastr.error( "删除失败："+repo.info )
                    }
                })

        };
        $scope.upForm = function () {
            var form = new FormData();
            var file = document.getElementById("choicefiles").files[0];
            form.append('file', file);
            $http({
                method: 'POST',
                url: '/api/job/fileserver/'+ vm.treeid,
                data: form,
                headers: {'Content-Type': undefined},
                transformRequest: angular.identity
            }).success(function (data) {
                if (data.stat){
                    vm.up_re = "上传成功";
                    setTimeout(function () {
                        document.getElementById("upresult123").style.display = 'none';
                    }, 2000);
                }
                vm.getFiles();
            }).error(function (data) {
                vm.up_re = "上传失败";
                document.getElementById("upresult").style.color = 'red';
                document.getElementById("upresult").style.display = 'none';
            })
        };
        vm.clickImport = function () {
            document.getElementById("choicefiles").click();
        };

        vm.cleanSelected = function () {
            $scope.selected = [];
            var from = $scope.formType;

            if (from == "ip"){
                $scope.allData = vm.machineData;
            }else if(from == "group"){
                $scope.allData = vm.groupData;
            }
        };

        vm.manageToken = function () {
            $uibModal.open({
                templateUrl: 'app/pages/business/file/token.html',
                controller: 'tokenController',
                controllerAs: 'token',
                backdrop: 'static',
                size: 'lg',
                keyboard: false,
                bindToController: true,
                resolve: {}
            });
        };

        vm.chioceover = function(){
            var choiceType = $scope.choiceType;
            if (choiceType == "choice") {
                $scope.selectedData.push($scope.s_file);
            } else {
                var filename = {'name': vm.inputFileName};
                $scope.selectedData.push(filename);
            }
            $uibModalInstance.close(
                $scope.selectedData
            );
        };

        $scope.updateSelectFile = function ($event, id, data) {
            $scope.s_file = data;
        };
        $scope.updateRadio = function ($event, id, data) {
            // var checkbox = $event.target;
            // var action = (checkbox.checked ? 'add' : 'remove');
            // updateSelected(action, id, data);
            $scope.radioselected['group'] = data
        };
        $scope.selectAll = function ($event) {
            var checkbox = $event.target;
            var action = (checkbox.checked ? 'add' : 'remove');
            for (var i = 0; i < $scope.allData.length; i++) {
                var entity = $scope.allData[i];
                updateSelected(action, entity.id, entity);
            }
        };
        // $scope.getSelectedClass = function (entity) {
        //     return $scope.isSelected(entity.id) ? 'selected' : '';
        // };
        $scope.isSelected = function (id) {
            return $scope.selected.indexOf(id) >= 0;
        };
        $scope.isSelectedAll = function () {
            if ($scope.selected.length){
                return $scope.selected.length === $scope.allData.length;
            }

        };
        vm.getFiles();


    }
})();

