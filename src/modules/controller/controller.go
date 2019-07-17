package controller

import (
	"bytes"
	"encoding/json"

	"github.com/er-story-line/story_api/src/modules/database"
)

// Controller holds all public API methods
type Controller struct {
	db database.Actions
}

// NewController creates a new controller for public routes
func NewController(db *database.DB) *Controller {
	return &Controller{db}
}

// Disconnect calls disconnect on db model
func (p *Controller) Disconnect() {
	p.db.Disconnect()
}

func jsonMarshal(entities interface{}) string {
	out, _ := json.Marshal(entities)
	var ret bytes.Buffer
	json.Indent(&ret, out, "", "\t")
	return ret.String()
}
