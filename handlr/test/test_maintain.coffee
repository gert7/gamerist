require("coffee-script")
Futures  = require("futures")
maintain = require("../handlr_maintain")
expect   = require("chai").expect
debug    = require("debug")("test")
fs   = require('fs')
path = require("path")

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

describe "maintain", ->
  it "do", (done) ->
    done()
