(function checkStatus () {
  window.checkAlert = function () {
    document.body.style.overflow = "hidden"
    const alertDialog = document.createElement("DIV");
    alertDialog.id = "alertDialog";
    alertDialog.style.position = "absolute";
    alertDialog.style.width = "100%"
    alertDialog.style.height = "100%"
    alertDialog.style.left = 0;
    alertDialog.style.top = 0;
    alertDialog.style.zIndex = 9999;
    alertDialog.style.backgroundColor = "rgba(0,0,0,.2)"
    alertHtml = `
      <ul style="position:absolute;left:50%;top:50%;margin:-167px 0  0 -239px!important;list-style:none;margin:0px;padding:0px;width:478px;height:334px;background-color:#fff;border-radius:5px;padding:17px">
        <li style="width: 80px;height: 80px; border: 4px solid #f8bb86;border-radius: 40px;border-radius: 50%;margin: 20px auto;padding: 0;position: relative;box-sizing: content-box;">
          <span style="position: absolute;width: 5px;height: 47px;left: 50%;top: 10px;border-radius: 2px;margin-left: -2px;background-color: #f8bb86;"></span>
          <span style="position: absolute; width: 7px;height: 7px;border-radius: 50%;margin-left: -3px;left: 50%; bottom: 10px;background-color: #f8bb86;"></span>
        </li>
        <li style="background:#fff;text-align:center;font-size:30px;height:95px;line-height:95px;border-left:1px solid #fff;border-right:1px solid #fff;color:#000">请先在OPEN-C3上登录！</li>
        <li style="text-align:center;font-weight:bold;line-height:25px; ">
        <input type="button" value="取消" onclick="checkCancel()" style="width:100px;height:45px;border:none;border-radius: 5px;font-weight: 500;background:#c1c1c1;color:#fff;box-shadow: none;font-size:17px;line-height:20px;outline:none;padding: 10px 32px;cursor: pointer;margin: 26px 5px 0;"/>
          <input type="button" value="确定" onclick="checkConfirm()" style="width:100px;height:45px;border:none;border-radius: 5px;font-weight: 500;background:rgb(221, 107, 85);color:#fff;box-shadow: none;font-size:17px;line-height:20px;outline:none;padding: 10px 32px;cursor: pointer;margin: 26px 5px 0;"/>
          </li>
      </ul>
    `
    alertDialog.innerHTML = alertHtml;
    document.body.appendChild(alertDialog);
    this.checkConfirm = function () {
      document.body.style.overflow = ""
      alertDialog.style.display = "none";
      window.open(window.location.origin)
    };
    this.checkCancel = function () {
      document.body.style.overflow = ""
      alertDialog.style.display = "none";
    }
    alertDialog.focus();
    document.body.onselectstart = function () { return false; };
  }

  fetch(window.location.origin + "/api/connector/connectorx/sso/userinfo")
    .then(function (response) {
      if (response.ok) {
        return response.json();
      }
      throw new Error("Network response was not ok.");
    })
    .then(function (data) {
      if (data.code === 10000) {
        checkAlert()
      }
    })
    .catch(function (error) {
      checkAlert()
    });
})()
