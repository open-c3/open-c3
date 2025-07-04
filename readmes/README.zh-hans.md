<div align="center">
  <a name="readme-top"></a>
  <a href="https://www.open-c3.online/demo.html" target="_blank"><img src="/c3-front/src/assets/images/open-c3-logo.jpeg" alt="Open-C3" width="100" /></a>
  
## 一个开源的 自动化运维 平台 (DevOps)

</div>
<br/>

## 什么是 Open-C3？

Open-C3 是一个开源的自动化运维平台，功能包括 CMDB、监控系统、发布系统、工单系统、流程系统 等，同时各子系统之间自动联动。是一个一体化的自动化运维平台。

## 快速启动

准备一个干净的 Linux Server (64 位，>= 4c8g)

```sh
curl -sSL https://raw.githubusercontent.com/open-c3/open-c3/v2.6.1/Installer/scripts/single.sh | OPENC3VERSION=v2.6.1 bash -s install 10.10.10.10
```

通过您的浏览器访问 Open-C3，地址为 `http://your-openc3-ip/`
- 用户名: `open-c3`
- 密码: `changeme`

## 截图
<table style="border-collapse: collapse; border: 1px solid black;">
  <tr>
    <td style="padding: 5px;background-color:#fff;"><img src= "https://github.com/user-attachments/assets/c3070a34-f1e4-42a9-b240-79056909e00b" alt="Open-C3 CMDB 首页"   /></td>
    <td style="padding: 5px;background-color:#fff;"><img src= "https://github.com/user-attachments/assets/15aff287-4cf1-4eed-8567-65567020df07" alt="Open-C3 CMDB 查看单个资源详情"   /></td>    
  </tr>
  <tr>
    <td style="padding: 5px;background-color:#fff;"><img src= "https://github.com/user-attachments/assets/ac21234e-71ec-49b3-9dd5-c02cf85ed1d8" alt="Open-C3 监控"   /></td>
    <td style="padding: 5px;background-color:#fff;"><img src= "https://github.com/user-attachments/assets/45ba808d-6d89-4aac-b09b-cc6fef4bad33" alt="Open-C3 监控"   /></td>
  </tr>
  <tr>
    <td style="padding: 5px;background-color:#fff;"><img src= "https://github.com/user-attachments/assets/1d52a93f-6b12-46df-ba1c-cad46ea66793" alt="Open-C3 监控"   /></td>     
    <td style="padding: 5px;background-color:#fff;"><img src= "https://github.com/user-attachments/assets/e3f50373-115b-42f4-86a3-9bd5afa085b7" alt="Open-C3 监控"   /></td>
  </tr>
  <tr>
    <td style="padding: 5px;background-color:#fff;"><img src= "https://github.com/user-attachments/assets/584b374f-b3e0-4321-a5a6-96c7be3eeea1" alt="Open-C3 CICD"   /></td>
    <td style="padding: 5px;background-color:#fff;"><img src= "https://github.com/user-attachments/assets/2bc1a7c2-07d9-4cf8-aa35-7e507cee5ef0" alt="Open-C3 CICD"   /></td>
  </tr>
  <tr>
    <td style="padding: 5px;background-color:#fff;"><img src= "https://github.com/user-attachments/assets/fd5a7401-0c4c-4218-b12a-905a59360423" alt="Open-C3 菜单"   /></td>
    <td style="padding: 5px;background-color:#fff;"><img src= "https://github.com/user-attachments/assets/9292eb7a-bba6-4477-af75-8c99f57af410" alt="Open-C3 工单"   /></td>
  </tr>
</table>

## 贡献

欢迎提交 PR 以作贡献。请参考 [CONTRIBUTING.md][contributing-link] 以获取指导。

## License

Copyright (c) 2020-2025 Open-C3, All rights reserved.

Licensed under The GNU General Public License version 2 (GPLv2) (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

https://www.gnu.org/licenses/gpl-2.0.html

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an " AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

<!-- Open-C3 official link -->
[contributing-link]: /CONTRIBUTING.md
