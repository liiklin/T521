Boom = require "boom"
Url = require "url"
Promise = require 'bluebird'
_ = require "underscore"

synonymPath = "synonym"

# synonym路由
exports.register = (server, options, next) ->
  db = server.app.db

  # groups
  server.route
    method: "GET"
    path: "/#{synonymPath}/groups"
    handler: (req, res) ->
      # 查询数据库
      db.group.find {} , {"_id": 0} , (err, result) ->
        if err
          return res Boom.wrap err, "Internal MongoDB error"
        res result

  server.route
    method: ["PUT","DELETE"]
    path: "/#{synonymPath}/groups/{id}"
    handler: (req, res) ->
      id = req.params.id
      findOpts =
          "id": id
      method = req.raw.req.method
      if method is "PUT"
        # 更新
        db.group.update findOpts, $set: req.payload, (err, result) ->
          if err
            return res Boom.wrap err, "Internal MongoDB error"
          if result.n is 0
            return res Boom.notFound()
          res "result": "success"
      else
        # 删除
        db.group.remove findOpts, (err, result) ->
          if err
            return res Boom.wrap err, "Internal MongoDB error"
          if result.n is 0
            return res Boom.notFound()
          res "result": "success"

  # cores
  server.route
    method: ["GET","POST"]
    path: "/#{synonymPath}/groups/{gid}/cores"
    handler: (req, res) ->
      gid = req.params.gid
      findOpts =
          "group_id": gid
      method = req.raw.req.method
      if method is "GET"
        uri = req.raw.req.url
        queryArgs = Url.parse(uri, true).query
        search = queryArgs.search or "*"
        if search isnt "*"
          findOpts.id = search
        #查询 group
        db.group.find "id": gid, (err, result) ->
          if result.length isnt 0
            db.core.find findOpts, (err, result) ->
              if err
                return res Boom.wrap err, "Internal MongoDB error"
              #精确查询到结果
              if result.length isnt 0
                contains = _.pluck result , "id"
                analogs = _.union _.flatten _.pluck result , "analogs"
                resObj =
                  "existed": true
                  "contains": contains
                  "analogs": if _.isEmpty analogs[0] then [] else analogs
                findContains =
                  "group_id": gid
                  "id": new RegExp ".*#{search}.*"
                db.core.find findContains, (err, result) ->
                  resObj.contains = _.extend resObj.contains , _.pluck result , "id"
                  res resObj
              # 没有精确查询到结果
              else
                findContains =
                  "group_id": gid
                  "id": new RegExp ".*#{search}.*"
                db.core.find findContains, (err, result) ->
                  resObj =
                    "existed": false
                    "contains": _.pluck result , "id"
                    "analogs": []
                  res resObj
          else
            # 插入groups
            saveOBj =
              "id": gid
              "descr":""
            db.group.save saveOBj, (err, result) ->
            resObj =
              "existed": false
              "contains": []
              "analogs": []
            res resObj
      else
        # 添加
        postData = req.payload
        saveArr = _.map postData , (data) ->
          "group_id": gid, "id": data
        taskLists = []
        _.each saveArr, (arr) ->
          task = new Promise (reslove, reject) ->
            db.core.find arr , (err, result) ->
              if result.length > 0
                reslove "success"
              else
                db.core.save arr , (err, result) ->
                  if err
                    reject "Internal MongoDB error"
                  else
                    reslove "success"
          taskLists.push task

        Promise.all taskLists
        .done ->
          console.log "taskLists save done"
          res "result": "success"

  server.route
    method: ["GET","DELETE"]
    path: "/#{synonymPath}/groups/{gid}/cores/{id}"
    handler: (req, res) ->
      gid = req.params.gid
      id = req.params.id
      findOpts =
          "group_id": gid
          "id": id
      method = req.raw.req.method
      if method is "GET"
        # 更新
        db.core.findOne findOpts, {"_id": 0} , (err, result) ->
          if err
            return res Boom.wrap err, "Internal MongoDB error"
          res result
      else
        # 删除
        db.core.remove findOpts, (err, result) ->
          if err
            return res Boom.wrap err, "Internal MongoDB error"
          if result.n is 0
            return res Boom.notFound()
          res "result": "success"

  # analogs
  server.route
    method: ["GET","POST"]
    path: "/#{synonymPath}/groups/{gid}/analogs"
    handler: (req, res) ->
      gid = req.params.gid
      findOpts =
          "group_id": gid
      method = req.raw.req.method
      if method is "GET"
        uri = req.raw.req.url
        queryArgs = Url.parse(uri, true).query
        search = queryArgs.search or "*"
        if search isnt "*"
          findOpts.id = search
        # 查询
        db.analog.find findOpts, {"_id": 0} , (err, result) ->
          if err
            return res Boom.wrap err, "Internal MongoDB error"
          res result
      else
        # 添加
        findOpts.id = req.payload.id
        db.analog.find findOpts, (err, result) ->
          if err
            return res Boom.wrap err, "Internal MongoDB error"
          if result.length is 0
            saveObj =
              "group_id": gid
              "id": req.payload.id
              "cores": [].push req.payload.cores
            db.analog.save saveObj, (err, result) ->
              if err
                return res Boom.wrap err, "Internal MongoDB error"
              res "result": "success"
          else
            updateObj =
              cores: req.payload.cores
            db.analog.update findOpts, $addToSet: updateObj , (err, result) ->
              if err
                return res Boom.wrap err, "Internal MongoDB error"
              res "result": "success"

  server.route
    method: ["GET","PUT","DELETE"]
    path: "/#{synonymPath}/groups/{gid}/analogs/{id}"
    handler: (req, res) ->
      gid = req.params.gid
      id = req.params.id
      findOpts =
          "group_id": gid
          "id": id
      method = req.raw.req.method
      if method is "GET"
        # 查询
        db.analog.findOne findOpts, {"_id": 0} , (err, result) ->
          if err
            return res Boom.wrap err, "Internal MongoDB error"
          cores = _.pluck result.cores
          res result
      else if method is "PUT"
        # 修改
        uri = req.raw.req.url
        queryArgs = Url.parse(uri, true).query
        action = queryArgs.action or ""
        if action is "unlink"
          updateObj =
            cores: req.payload.core
          db.analog.update findOpts, $pull: updateObj, (err, result) ->
            if err
              return res Boom.wrap err, "Internal MongoDB error"
            if result.n is 0
              return res Boom.notFound()
            db.analog.findOne findOpts, (err, result) ->
              if result.cores.length is 0
                db.analog.remove findOpts
            res "result": "success"
        else
          resObj =
            "error":"action is unlink"
          res resObj
          .code 404
      else
        # 删除
        db.analog.remove findOpts, (err, result) ->
          if err
            return res Boom.wrap err, "Internal MongoDB error"
          if result.n is 0
            return res Boom.notFound()
          res "result": "success"

  next()

exports.register.attributes = name: "routes-#{synonymPath}"
