# source-map-support
require("source-map-support").install()

# hapi
Hapi = require "hapi"
Good = require "good"
mongojs = require "mongojs"

server = new Hapi.Server()
# 设置端口
server.connection
  port: 3000

# db 设置
# 生产环境和开发环境
if process.env.NODE_ENV is "production"
  server.app.db = mongojs("db:27017/local", ["words","group","core","analog"]) ;
else
  server.app.db = mongojs("192.168.59.103:27017/local", ["words","group","core","analog"]) ;

# register设置
registerArr = [
  {
    register: require("./searchrec")
    options: {}
  } ,
  {
    register: require("./synonym")
    options: {}
  } , {
    register: Good
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
    console.log "Server is running at:#{server.info.uri}"
