Boom = require 'boom'
Url = require "url"
# models
wordsModel = require "../models/words"

# searchrec路由
exports.register = (server, options, next) ->
  db = server.plugins['hapi-mongoose'].connection
  mongoose = server.plugins['hapi-mongoose'].lib
  Schema = mongoose.Schema
  # entry init
  wordSchema = new Schema wordsModel
  Word = db.model 'words', wordSchema

  server.route
    method: "GET"
    path: "/groups/{gid}/words"
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
      Word.find {} , {"_id": 0,"__v": 0}
      .then (words) ->
        res words
      .catch (err) ->
        console.error err
        res Boom.wrap err

  server.route
    method: ["PUT","DELETE"]
    path: "/groups/{gid}/words/{id}"
    handler: (req, res) ->
      gid = req.params.gid
      id = req.params.id
      findOpts =
          "group_id": gid
          "id": id
      method = req.raw.req.method
      if method is "PUT"
        # 更新
        Word.update findOpts, $set: req.payload
        .then (result) ->
          if result.n is 0
            return res Boom.notFound()
          res "result": "success"
        .catch (err) ->
          console.error err
          res Boom.wrap err
      else
      # 删除
        Word.remove findOpts
        .then (result) ->
          if result.n is 0
            return res Boom.notFound()
          res "result": "success"
        .catch (err) ->
          console.error err
          res Boom.wrap err

  next()

exports.register.attributes = name: "routes-searchrec"
