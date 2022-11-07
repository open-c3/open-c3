package cookie

import (
	"net/http"

	"openc3.org/trouble-ticketing/config"
	"github.com/gorilla/securecookie"
)

var SecureCookie *securecookie.SecureCookie

func Init() {
	var hashKey = []byte(config.Config().Salt)
	var blockKey = []byte(nil)
	SecureCookie = securecookie.New(hashKey, blockKey)
}

// 读取本地cookie，
func ReadCookie(w http.ResponseWriter, r *http.Request) (token string, found bool) {
	if cookie, err := r.Cookie(config.Config().Sso.CookieKey); err == nil {
		return cookie.Value, true
	}
	return "", false
}
func DecodeCookie(text string) (token string) {
	value := make(map[string]interface{})
	if err := SecureCookie.Decode(config.Config().Sso.CookieKey, text, &value); err == nil {
		token = value["token"].(string)
		return
	}
	return
}

// 写cookie到u
func WriteCookie(w http.ResponseWriter, token string) error {

	value := make(map[string]interface{})
	value["token"] = token

	encoded, err := SecureCookie.Encode(config.Config().Sso.CookieKey, value)
	if err != nil {
		return err
	}

	cookie := &http.Cookie{
		Name:     config.Config().Sso.CookieKey,
		Value:    encoded,
		Path:     "/",
		MaxAge:   3600 * 24 * 8,
		HttpOnly: true,
	}
	http.SetCookie(w, cookie)

	return nil
}

// 清空u
func RemoveToken(w http.ResponseWriter) error {

	value := make(map[string]interface{})
	value["token"] = ""
	encoded, err := SecureCookie.Encode(config.Config().Sso.CookieKey, value)
	if err != nil {
		return err
	}

	cookie := &http.Cookie{
		Name:   config.Config().Sso.CookieKey,
		Value:  encoded,
		Path:   "/",
		MaxAge: -1,
	}
	http.SetCookie(w, cookie)

	return nil
}
