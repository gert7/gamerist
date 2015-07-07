amqp = require('amqplib')
nedb = require('nedb')
path = require('path')
debug = require('debug')('front')

require("coffee-script")

require('./handlr_portlist')

fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

require('./handlr_mq_sub')
require('./handlr_downward')

