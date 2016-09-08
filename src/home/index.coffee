# source-map-support
require("source-map-support").install()

# hapi
Hapi = require "hapi"
Good = require "good"
mongojs = require "mongojs"

server = new Hapi.Server()
# 设置端口
server.connection
  host: "localhost"
  port: 3000

# db 设置
server.app.db = mongojs("db:27017/local", ["words","group","core","analog"]) ;

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
    console.log "Server is running at:", server.info.uri
