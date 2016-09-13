# source-map-support
require("source-map-support").install()

# hapi
Hapi = require "hapi"

server = new Hapi.Server()
# 设置端口
server.connection
  port: 3000

# db 设置
# 生产环境和开发环境
uri = "mongodb://192.168.59.103:27017/local"
if process.env.NODE_ENV is "production"
  uri = "db:27017/local"

pluginOptions =
    bluebird: true
    uri: uri

# register设置
registerArr = [
  {
    register: require "hapi-mongoose"
    options: pluginOptions
  } ,
  {
    register: require("./home/searchrec")
    options: {}
  } ,
  {
    register: require("./home/synonym")
    options: {}
  } ,
  {
    register : require('blipp')
  },
  {
    register: require "good"
    options:
      reporters:
        console: [
            module: "good-squeeze"
            name: "Squeeze"
            args: [
                response: "*"
                log: "*"
            ]
        module: "good-console"
        "stdout"
        ]
  }
]

server.register registerArr , (err) ->
  if err
    console.error err
    throw err

  server.start (err) ->
    if err
      throw err
    console.log "Server is running at:#{server.info.uri} in #{process.env.NODE_ENV}"
