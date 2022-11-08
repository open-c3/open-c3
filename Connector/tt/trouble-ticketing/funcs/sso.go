package funcs

import (
	"openc3.org/trouble-ticketing/config"
	"openc3.org/trouble-ticketing/http/cookie"
	"encoding/json"
	"io/ioutil"

	"errors"
	"fmt"
	"log"
	"net/http"
)

type SSOUser struct {
	Name   string `json:"name"`
	OAName string `json:"oaname"`
	Email  string `json:"email"`
}

// oa用户信息
type BaseOaUsers struct {
	Id             int64  `xorm:"id" json:"id"`
	Email          string `xorm:"email" json:"email"`
	AccountName    string `xorm:"accountName" json:"accountName"`
	AccountId      string `xorm:"accountId" json:"accountId"`
	AccountNo      string `xorm:"accountNo" json:"accountNo"`
	Mobile         string `xorm:"mobile" json:"mobile"`
	TwoPkDept      string `xorm:"twoPkDept" json:"twoPkDept"`
	TwoDeptName    string `xorm:"twoDeptName" json:"twoDeptName"`
	TwoLeaderId    string `xorm:"twoLeaderId" json:"twoLeaderId"`
	TwoLeaderName  string `xorm:"twoLeaderName" json:"twoLeaderName"`
	OnePkDept      string `xorm:"onePkDept" json:"onePkDept"`
	OneDeptName    string `xorm:"oneDeptName" json:"oneDeptName"`
	OneLeaderId    string `xorm:"oneLeaderId" json:"oneLeaderId"`
	OneLeaderName  string `xorm:"oneLeaderName" json:"oneLeaderName"`
	SybPkDept      string `xorm:"sybPkDept" json:"sybPkDept"`
	SybDeptName    string `xorm:"sybDeptName" json:"sybDeptName"`
	SybLeaderId    string `xorm:"sybLeaderId" json:"sybLeaderId"`
	SybLeaderName  string `xorm:"sybLeaderName" json:"sybLeaderName"`
	CostCenterCode string `xorm:"costCenterCode" json:"costCenterCode"`
	CostCenter     string `xorm:"costCenter" json:"costCenter"`
}

func LoginRequire(w http.ResponseWriter, r *http.Request) (user SSOUser, token string, err error) {
	token, found := cookie.ReadCookie(w, r)
	if !found {
		token = r.Header.Get("token")
		if token == "" {
			err = errors.New("no token")
			return
		}
	}
	user, err = querySsoUser(token)
	if err != nil {
		log.Println("err", err.Error())
		return
	}
        user.OAName = user.Name
	if user.OAName == "" {
		err = errors.New("no username")
		return
	}
	return
}
func querySsoUser(token string) (user SSOUser, err error) {
	url := "http://api.connector.open-c3.org/connectorx/sso/userinfo"
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return user, err
	}
	req.Header.Set("Cookie", fmt.Sprintf("%s=%s", config.Config().Sso.CookieKey, token))

	client := &http.Client{}
	resp, err := client.Do(req)

	if err != nil {
		return user, err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return user, err
	}
	err = json.Unmarshal(body, &user)
	if err != nil {
		return user, err
	}
	return user, nil
}

// get oa info
func GetOaInfo(email string) (user BaseOaUsers, err error) {

	url := fmt.Sprintf("%s/new/getdepbyname", config.Config().Sso.URL)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return user, err
	}
	req.Header.Set("name", email)

	client := &http.Client{}
	resp, err := client.Do(req)

	if err != nil {
		return user, err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return user, err
	}
	err = json.Unmarshal(body, &user)
	if err != nil {
		return user, err
	}
	return user, nil
}
