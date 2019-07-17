package config

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	_ "os"
	"time"
)

// 設定ファイルの値を表現する構造体
type DBConfig struct {
	// Database
	DRIVER      string
	USER        string
	PASSWORD    string
	DB          string
	HOST        string
	STAGINGHOST string
	PORT        string
	STAGINGPORT string
}

type APPConfig struct {
	// Application
	APP_PORT string
}

type KEYConfig struct {
	// Keys
	KEYPATH     string
	PRIVATE_KEY string
	PUBLIC_KEY  string
	SIGN_METHOD string
	SSL_KEY     string
	SSL_CERT    string
}

const (
	// JWT
	ISSURE       string        = "story_line.com"
	EXPIRED_HOUR time.Duration = time.Duration(8)
)

func Parse(filename string) (DBConfig, APPConfig, KEYConfig, error) {

	var c DBConfig
	var a APPConfig
	var k KEYConfig

	jsonString, err := ioutil.ReadFile(filename)
	if err != nil {
		fmt.Println("error" + err.Error())
		return c, a, k, err
	}
	err = json.Unmarshal(jsonString, &c)
	if err != nil {
		fmt.Println("error" + err.Error())
		return c, a, k, err
	}
	err = json.Unmarshal(jsonString, &a)
	if err != nil {
		fmt.Println("error" + err.Error())
		return c, a, k, err
	}
	err = json.Unmarshal(jsonString, &k)
	if err != nil {
		fmt.Println("error" + err.Error())
		return c, a, k, err
	}

	return c, a, k, err
}
