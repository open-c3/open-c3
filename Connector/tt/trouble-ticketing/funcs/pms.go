package funcs

import (
	"openc3.org/trouble-ticketing/config"
	"net/http"
	"strings"

	"encoding/json"
	"io/ioutil"
)

// check user role
func CheckPmsRole(r *http.Request, role string) bool {
	type resStruct struct {
		Code int64  `json:"code"`
		Admin string  `json:"admin"`
		Msg  string `json:"msg"`
	}

        addr := "http://api.connector.open-c3.org/connectorx/sso/userinfo"

	// http req
	client := &http.Client{}
	req, _ := http.NewRequest("GET", addr, strings.NewReader(""))

	// get cookie
	cook, _ := r.Cookie(config.Config().Sso.CookieKey)
	req.Header.Set("cookie", cook.String())

	resp, _ := client.Do(req)
	body, _ := ioutil.ReadAll(resp.Body)

	var resS resStruct
	json.Unmarshal(body, &resS)

        if  resS.Admin == "1" {
            return true
        }
        return false
}
