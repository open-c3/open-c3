<div align="center">
  <a name="readme-top"></a>
  <a href="https://www.open-c3.online/demo.html" target="_blank"><img src="/c3-front/src/assets/images/open-c3-logo.jpeg" alt="Open-C3" width="100" /></a>
  
## 一個開源的自動化運維平臺（DevOps）

</div>
<br/>

## 什麼是Open-C3?

Open-C3是一個開源的自動化運維平臺，功能包括CMDB、監控系統、發佈系統、工單系統、流程系統等，同時各子系統之間自動聯動。 是一個一體化的自動化運維平臺。


## 快速開始

準備一台乾淨的 Linux 伺服器 (64 位，>= 4c8g)

```sh
curl -sSL https://raw.githubusercontent.com/open-c3/open-c3/v2.6.1/Installer/scripts/single.sh | OPENC3VERSION=v2.6.1 bash -s install 10.10.10.10
```

在您的瀏覽器中訪問 Open-C3：`http://your-openc3-ip/`
- 用戶名：`open-c3`
- 密碼：`changeme`

## 截圖
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

## 貢獻

歡迎提交 PR 以作貢獻。請參考 [CONTRIBUTING.md][contributing-link] 獲取指導。

## 授權

Copyright (c) 2020-2025 Open-C3, All rights reserved.

Licensed under The GNU General Public License version 2 (GPLv2) (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

https://www.gnu.org/licenses/gpl-2.0.html

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an " AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

<!-- Open-C3 official link -->
[contributing-link]: /CONTRIBUTING.md
