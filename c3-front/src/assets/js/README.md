# 前端引用文件

## 引用插件源文件

- **[xlsx.full.min.js](/c3-front//src/assets/js/xlsx.full.min.js) (本地路径)**

- **[file-server.js](/c3-front//src/assets/js/file-server.js) (本地路径)**

> xlsx.full.min.js与 file-server.js这两个文件是使用xlsx插件相关，为了保持系统稳定性，取消CDN方式加载，使用固定版本的代码进行加载， 下面是源文件链接

- [xlsx.full.min.js](https://unpkg.com/xlsx/dist/xlsx.full.min.js)
- [file-server.js](https://cdn.jsdelivr.net/npm/file-saver@2.0.5)

## 登录状态检查脚本

- **[check-login.js](/c3-front/src/assets/js/check-login.js)**

> check-login.js文件生效的情况是当从监控面板跳转到 `grafana` 和 `prometheus` 等外链新页面时， 状态不能够同步，通过这个脚本通过OPEN-C3接口检测登录态 从而通过弹窗提示用户是否需要重新登录
