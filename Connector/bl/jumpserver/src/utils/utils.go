package utils

import (
	"bl/src/logger"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"math/rand"
	"net/http"
	"net/url"
	"path"
	"strings"
	"time"

	"github.com/google/uuid"
)

func createHttpClient() http.Client {
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	return http.Client{
		Transport: tr,
		Timeout:   time.Second * 60,
	}
}

func DoNetworkRequest(method string, url, postData string, headMap map[string]string, respValue interface{}) ([]byte, *int, error) {
	maxRetries := 3

	var resp *http.Response
	var err error
	for i := 0; i < maxRetries; i++ {
		client := createHttpClient()
		req, err := http.NewRequest(method, url, strings.NewReader(postData))
		if err != nil {
			return nil, nil, err
		}

		for k, v := range headMap {
			req.Header.Set(k, v)
		}
		resp, err = client.Do(req)
		if err == nil {
			break
		}
		time.Sleep(time.Second)
	}

	if err != nil {
		return nil, nil, err
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, nil, err
	}

	if respValue != nil {
		err = json.Unmarshal(body, &respValue)
		if err != nil {
			return body, nil, err
		}
	}
	statusCode := resp.StatusCode

	err = resp.Body.Close()
	if err != nil {
		return body, nil, err
	}
	return body, &statusCode, nil
}

func GetUrlWithParams(serverAddr string, uri string, params map[string]string) (*string, error) {
	u, err := url.Parse(serverAddr)
	if err != nil {
		logger.FsErrorf("GetUrlWithParams.Parse.err: %v", err)
		return nil, err
	}
	u.Path = path.Join(u.Path, uri)
	if strings.HasSuffix(uri, "/") {
		u.Path = fmt.Sprintf("%v/", u.Path)
	}

	urlA, err := url.Parse(u.String())
	if err != nil {
		logger.FsErrorf("GetUrlWithParams.Parse.err1: %v", err)
		return nil, err
	}

	if len(params) > 0 {

		values := urlA.Query()

		for k, v := range params {
			values.Add(k, v)
		}
		urlA.RawQuery = values.Encode()
	}

	result := urlA.String()
	return &result, nil
}

func ToJsonString(data interface{}) string {
	b, _ := json.Marshal(data)
	return string(b)
}

func GetUUID() (*string, error) {
	id, err := uuid.NewUUID()
	if err != nil {
		return nil, err
	}
	uid := id.String()
	return &uid, nil
}

func AddEleIfNotExist(list []string, s string) []string {
	exist := false
	for _, item := range list {
		if item == s {
			exist = true
			break
		}
	}
	if !exist {
		list = append(list, s)
	}
	return list
}

func GenCustomTypePassword(passwordLength, minSpecialChar, minNum, minUpperCase, minLowerCase int) string {
	var (
		lowerCharSet   = "abcdedfghijklmnopqrst"
		upperCharSet   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		specialCharSet = "!@#$%&*"
		numberSet      = "0123456789"
		allCharSet     = lowerCharSet + upperCharSet + specialCharSet + numberSet
	)

	s1 := rand.NewSource(time.Now().UnixNano())
	r1 := rand.New(s1)

	var password strings.Builder

	// Set special character
	for i := 0; i < minSpecialChar; i++ {
		random := r1.Intn(len(specialCharSet))
		password.WriteString(string(specialCharSet[random]))
	}

	// Set numeric
	for i := 0; i < minNum; i++ {
		random := r1.Intn(len(numberSet))
		password.WriteString(string(numberSet[random]))
	}

	// Set uppercase
	for i := 0; i < minUpperCase; i++ {
		random := r1.Intn(len(upperCharSet))
		password.WriteString(string(upperCharSet[random]))
	}

	// Set lowercase
	for i := 0; i < minLowerCase; i++ {
		random := r1.Intn(len(lowerCharSet))
		password.WriteString(string(lowerCharSet[random]))
	}

	remainingLength := passwordLength - minSpecialChar - minNum - minUpperCase - minLowerCase
	for i := 0; i < remainingLength; i++ {
		random := r1.Intn(len(allCharSet))
		password.WriteString(string(allCharSet[random]))
	}
	inRune := []rune(password.String())
	r1.Shuffle(len(inRune), func(i, j int) {
		inRune[i], inRune[j] = inRune[j], inRune[i]
	})
	return string(inRune)
}
