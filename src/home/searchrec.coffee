Boom = require 'boom'
Url = require "url"

searchrecPath = "searchrec"

# searchrec路由
exports.register = (server, options, next) ->
  db = server.app.db

  server.route
    method: "GET"
    path: "/#{searchrecPath}/groups/{gid}/words"
    handler: (req, res) ->
      uri = req.raw.req.url
      queryArgs = Url.parse(uri, true).query
      gid = req.params.gid
      top = Number queryArgs.top or "20"
      state = queryArgs.state or ""
      findOpts =
        "group_id": gid
        "times":
          $gt: top
      if state isnt ""
        findOpts.state = state
      # 查询数据库
      db.words.find findOpts, {"_id": 0} , (err, result) ->
        if err
          return res Boom.wrap err, "Internal MongoDB error"
        res result

  server.route
    method: ["PUT","DELETE"]
    path: "/#{searchrecPath}/groups/{gid}/words/{id}"
    handler: (req, res) ->
      gid = req.params.gid
      id = req.params.id
      findOpts =
          "group_id": gid
          "id": id
      method = req.raw.req.method
      if method is "PUT"
        # 更新
        db.words.update findOpts, $set: req.payload, (err, result) ->
          if err
            return res Boom.wrap err, "Internal MongoDB error"
          if result.n is 0
            return res Boom.notFound()
          res "result": "success"
      else
      # 删除
        db.words.remove findOpts, (err, result) ->
          if err
            return res Boom.wrap err, "Internal MongoDB error"
          if result.n is 0
            return res Boom.notFound()
          res "result": "success"

  next()

exports.register.attributes = name: "routes-#{searchrecPath}"
