package orm

import (
	"openc3.org/trouble-ticketing/config"
	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql"
)

var Db *gorm.DB

func InitMysql() {

	var err error
	cfg := config.Config()
	Db, err = gorm.Open("mysql", cfg.Mysql.Addr)

	gorm.DefaultTableNameHandler = func(db *gorm.DB, defaultTableName string) string {
		return "openc3_tt_" + defaultTableName
	}

	Db.SingularTable(true)

	if err != nil {
		panic(err)
	}

	if cfg.Debug {
		//Db.Debug()
		Db.LogMode(true)
	}

}
