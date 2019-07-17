package main

import (
	"es-login-jwt/src/modules/models"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	jwt "github.com/dgrijalva/jwt-go"
	"github.com/er-story-line/story_api/src/modules/config"
	controllers "github.com/er-story-line/story_api/src/modules/controller"
	"github.com/er-story-line/story_api/src/modules/database"
	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
)

const (
	CONFFILE        string = "./conf/config.json"
	APIVERSION      string = "/V0"
	RESTRICTEDGROUP string = "/protected"
)

func main() {
	// Configure
	dbconf, appconf, keyconf, err := config.Parse(CONFFILE)
	if err != nil {
		log.Panic(err)
	}
	dbhost := dbconf.HOST
	dbport := dbconf.PORT
	env := os.Getenv("DEV_ENV")
	if env != "local" {
		dbhost = dbconf.STAGINGHOST
		dbport = dbconf.STAGINGPORT
	}

	// DB
	conn, sess, _, err := database.NewDB(dbconf.DRIVER, "postgres://"+dbconf.USER+":"+dbconf.PASSWORD+"@"+dbhost+":"+dbport+"/"+dbconf.DB+"?sslmode=disable")
	if err != nil {
		log.Panic(err)
	}

	db := &database.DB{conn, sess}
	cont := controllers.NewController(db)
	log.Println(cont)

	// Echo instance
	e := echo.New()

	// protocols
	e.GET("/request", func(c echo.Context) error {
		req := c.Request()
		format := `
<code>
Protocol: %s<br>
Host: %s<br>
Remote address: %s<br>
Method: %s<br>
Path: %s<br>
</code>
 		`
		return c.HTML(http.StatusOK, fmt.Sprintf(format, req.Proto, req.Host, req.RemoteAddr, req.Method, req.URL.Path))
	})

	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())
	e.Use(middleware.CORS())

	// PKI keys
	keyData, _ := ioutil.ReadFile(keyconf.KEYPATH + keyconf.PRIVATE_KEY)
	_, err = jwt.ParseRSAPrivateKeyFromPEM(keyData)
	if err != nil {
		log.Panic(err)
	}

	pubkeyData, _ := ioutil.ReadFile(keyconf.KEYPATH + keyconf.PUBLIC_KEY)
	pubkey, err := jwt.ParseRSAPublicKeyFromPEM(pubkeyData)
	if err != nil {
		log.Panic(err)
	}

	// restricted group
	r := e.Group(relativePath(RESTRICTEDGROUP))

	customJWT := middleware.JWTConfig{
		Claims:        &models.JwtCustomClaims{},
		SigningKey:    pubkey,
		SigningMethod: keyconf.SIGN_METHOD,
	}

	// Check jwt
	r.Use(middleware.JWTWithConfig(customJWT))

	// Start server
	if keyconf.SSL_CERT != "" && keyconf.SSL_KEY != "" {
		e.Logger.Fatal(e.StartTLS(":"+appconf.APP_PORT, keyconf.KEYPATH+keyconf.SSL_CERT, keyconf.KEYPATH+keyconf.SSL_KEY))
	} else {
		e.Logger.Fatal(e.Start(":" + appconf.APP_PORT))
	}
}

func relativePath(target string) string {
	return APIVERSION + target
}
