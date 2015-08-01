fs     = require('fs')
Config = JSON.parse(fs.readFileSync('./config.json', 'utf8'))

Config.selfname = (process.env.HANDLRNAME or Config.selfname)

exports.conf = Config

