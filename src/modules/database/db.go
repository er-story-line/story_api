package database

import (
	"database/sql"
	"errors"
	"fmt"
	"os"

	"github.com/gocraft/dbr"
)

type Actions interface {
	Disconnect() error
	Begin() (*TX, error)
	GetSession() *dbr.Session
	GetDB() *DB
}

type DB struct {
	*dbr.Connection
	*dbr.Session
}

type TX struct {
	Transaction *dbr.Tx
}

// Transactionable SessionでもTransactionでも関数が実行できる様にするため、下記を定義
type Transactionable interface {
	Exec(query string, args ...interface{}) (sql.Result, error)
	QueryRow(query string, args ...interface{}) *sql.Row
	Query(query string, args ...interface{}) (*sql.Rows, error)
	Select(column ...string) *dbr.SelectBuilder
	SelectBySql(query string, value ...interface{}) *dbr.SelectBuilder
	InsertInto(table string) *dbr.InsertBuilder
	Update(table string) *dbr.UpdateBuilder
	DeleteFrom(table string) *dbr.DeleteBuilder
}

func NewDB(driverName, conninfo string) (*dbr.Connection, *dbr.Session, string, error) {
	conn, err := dbr.Open(driverName, conninfo, nil)
	if err != nil {
		return nil, nil, "", err
	}

	err = conn.Ping()
	if err != nil {
		fmt.Fprintln(os.Stderr, "[WARN] database ping does not respond in intializing")
	}

	sess := conn.NewSession(nil)
	return conn, sess, conninfo, nil
}

// EscapeSQL with dbr InterpolateForDialect. Useful for long concatenated queries
// with user provided values
func (db *DB) EscapeSQL(query string, injectionVals ...interface{}) (string, error) {
	var injections []interface{}
	for _, value := range injectionVals {
		injections = append(injections, value)
	}
	escapedQuery, err := dbr.InterpolateForDialect(query, injections, db.Connection.Dialect)
	if err != nil {
		return "", err
	}

	return escapedQuery, nil
}

func (db *DB) Disconnect() error {
	if db == nil {
		return errors.New("database instance is nil")
	}

	err := db.Session.Close()
	if err != nil {
		return err
	}

	return db.Connection.Close()
}

func (db *DB) GetDB() *DB {
	return db
}

func (db *DB) Begin() (*TX, error) {
	tx, err := db.Session.Begin()
	if err != nil {
		return nil, err
	}

	return &TX{Transaction: tx}, nil
}

// GetSession get non-transaction Session for Selects
func (db *DB) GetSession() *dbr.Session {
	return db.Session
}

func (tx *TX) RollbackUnlessCommitted() {
	tx.Transaction.RollbackUnlessCommitted()
}

func (tx *TX) Commit() error {
	return tx.Transaction.Commit()
}
