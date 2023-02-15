package config

import (
	//	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"sync"

	//"openc3.org/trouble-ticketing/algorithm"

	"github.com/toolkits/file"
)

type GlobalConfig struct {
	Debug  bool   `json:"debug"`
	Salt   string `json:"salt"`
	Dbname string `json:"dbname"`
	HTTP   struct {
		Enabled bool   `json:"enabled"`
		Listen  string `json:"listen"`
	} `json:"http"`
	Mysql struct {
		Addr string `json:"addr"`
		User string `json:"user"`
		Pass string `json:"pass"`
		Idle int    `json:"idle"`
		Max  int    `json:"max"`
	} `json:"mysql"`
	Web struct {
		Dist string `json:"dist"`
		Src  string `json:"src"`
	} `json:"web"`
	Sso struct {
		URL       string `json:"url"`
		CookieKey string `json:"cookiekey"`
	} `json:"sso"`
	Attachment   string `json:"attachment"`
	WorkflowList []struct {
		KeywordList []string `json:"keyword_list"`
		// WorkGroupId 和 GroupUserId 的值有可能需要从系统参数中获取
		// 可以填具体的数据库记录id或者组名称或者用户名称
		WorkGroupId interface{} `json:"work_group_id"`
		GroupUserId interface{} `json:"group_user_id"`
	} `json:"workflow_list"`
}

func (this *GlobalConfig) Decryption() {
	//key := algorithm.Substr(this.Salt, 0, 24)
	// mysql password
	//orign, _ := base64.StdEncoding.DecodeString(this.Mysql.Pass)
	//passbyte, _ := algorithm.TripleDesDecrypt([]byte(orign), []byte(key))
	//this.Mysql.Addr = this.Mysql.User + ":" + string(passbyte) + this.Mysql.Addr
	this.Mysql.Addr = this.Mysql.User + ":" + this.Mysql.Pass + this.Mysql.Addr
}

var (
	ConfigFile string
	config     *GlobalConfig
	configLock = new(sync.RWMutex)
)

func Config() *GlobalConfig {
	configLock.RLock()
	defer configLock.RUnlock()
	return config
}

func Parse(cfg string) error {

	// filelog, err := os.Create("result.log")
	// logger = log.New(filelog, "", log.LstdFlags|log.Llongfile)

	if cfg == "" {
		return fmt.Errorf("use -c to specify configuration file")
	}

	if !file.IsExist(cfg) {
		return fmt.Errorf("configuration file %s is nonexistent", cfg)
	}

	ConfigFile = cfg

	configContent, err := file.ToTrimString(cfg)
	if err != nil {
		return fmt.Errorf("read configuration file %s fail %s", cfg, err.Error())
	}

	var c GlobalConfig
	err = json.Unmarshal([]byte(configContent), &c)
	if err != nil {
		return fmt.Errorf("parse configuration file %s fail %s", cfg, err.Error())
	}

	configLock.Lock()
	defer configLock.Unlock()
	c.Decryption()
	config = &c
	log.Println(c.Mysql.Addr)
	log.Println("load configuration file", cfg, "successfully")
	return nil
}
