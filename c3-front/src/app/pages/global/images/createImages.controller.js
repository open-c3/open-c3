(function() {
    'use strict';

    angular
        .module('openc3')
        .controller('CreateImagesController', CreateImagesController);

    function CreateImagesController($uibModalInstance, $state, $http, $scope, homereload, imagesid, title, $injector ) {

        var vm = this;
        vm.title = title
        vm.cancel = function(){ $uibModalInstance.dismiss()};
        vm.postData = { share: 'false' };
        vm.uploadstatus = 0;
        vm.imagesid = imagesid

        var toastr = toastr || $injector.get('toastr');

        vm.siteaddr = window.location.protocol + '//' + window.location.host;

        vm.bytesToSize = function(bytes) {
            if (bytes === 0) return '0 B';
            var k = 1000, // or 1024
                sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
                i = Math.floor(Math.log(bytes) / Math.log(k));

           return (bytes / Math.pow(k, i)).toPrecision(3) + ' ' + sizes[i];
        }


        vm.loadimagesinfo = function( imagesid )
        {
            $http.get('/api/ci/images/' + imagesid + '/upload' ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.uploadstatus = response.data.data
                    }else {
                        swal({ title:'检测镜像失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response){
                    swal({ title:'检查镜像失败', text: response.status, type:'error' });
                });

        }
        if( imagesid )
        {
            $http.get('/api/ci/images/' + imagesid ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        vm.postData = response.data.data
                    }else {
                        swal({ title:'获取镜像详情失败', text: response.data.info, type:'error' });
                    }
                },
                function errorCallback (response){
                    swal({ title:'获取镜像详情失败', text: response.status, type:'error' });
                });

                vm.loadimagesinfo( imagesid )
        }

        vm.saveImages = function(){
            var uri = '/api/ci/images';
            if( imagesid )
            {
                uri = '/api/ci/images/' + imagesid;
            }
            $http.post(uri, vm.postData ).then(
                function successCallback(response) {
                    if (response.data.stat){
                        homereload();
                        vm.cancel();
                    }else {
                        swal({ title:'保存镜像失败', text: response.data.info, type:'error' });
                    }
                }
            );
        };

        $scope.upForm = function () {
            $("#upload_progressBar_Module").css("display","block");
            var file = document.getElementById("choicefilesx").files[0];
            var name = document.getElementById("choicefilesx").files[0].name;
            $(".newFile").parents("div.col-sm-10").find("input[name='newFileMsg']").attr("data-name",name);
            var url = '/api/ci/uploadv2/images/' + imagesid + '/upload';

            var piece = 1024 * 1024 * 24;
            var len = Math.ceil(file.size/piece);
            var start = 0;
            var end = start + piece;
            var start_time = new Date().getTime();

            var seq = 0;
            function upload(){
                if (seq<len){
                    var chunk = file.slice(start, end);
                    var form = new FormData();
                    var xhr = new XMLHttpRequest();

                    form.append("filesize", file.size);
                    form.append("file", chunk);
                    form.append("len", len);
                    form.append("seq", seq);
                    xhr.open("post", url, true);
                    xhr.upload.onprogress=function(e){
                        var loaded = e.loaded+seq*piece;
                        if (e.lengthComputable){
                            $("#upload_progressBar").css("width",Math.round(loaded / file.size * 100) + "%");
                            $("#upload_progressBar").html(Math.round(loaded / file.size * 100) + "%");
                            $("#percentage").html("已上传"+ Math.round(loaded / file.size * 100) + "%");
                        }
                        //速度
                        var now = new Date().getTime();
                        var time = (now-start_time)/1000; //单位为s
                        var speed = loaded/time;
                        var bspeed = speed;
                        var units = 'b/s';
                        if(speed/1024>1){
                            speed = speed/1024;
                            units = 'k/s';
                        }
                        if(speed/1024>1){
                            speed = speed/1024;
                            units = 'M/s';
                        }
                        speed = speed.toFixed(1);
                        //剩余时间
                        var resttime = ((file.size-loaded)/bspeed).toFixed(1);
                        $("#time").html('，速度：' + speed + units + '，剩余时间：' + Math.abs(resttime) + 's');
                    };
                    xhr.onload=function(){
                        if (xhr.status == 200) {
                            var res = JSON.parse(xhr.responseText);
                            if (res.stat){
                                if (res.data.done){
                                    vm.loadimagesinfo( imagesid );
                                    seq = len;
                                    return;
                                }
                                //执行下一次请求
                                start = end;
                                end = start + piece;
                                seq++;
                                upload();
                            }else{
                                toastr.error("上传失败:" + xhr.responseText);
                                seq = len;
                                return;
                            }
                        }else{
                            toastr.error("上传失败:" + xhr.responseText);
                            seq = len;
                            return;
                        }
                    };
                    xhr.send(form);
                }
            }
            upload();
        };

        vm.clickImport = function () {
            document.getElementById("choicefilesx").click();
        };
    }
})();
