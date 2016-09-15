Boom = require "boom"
Url = require "url"
Promise = require "bluebird"
_ = require "underscore"
# models
groupModel = require "../models/group"
coreModel = require "../models/core"
analogModel = require "../models/analog"

# synonym路由
exports.register = (server, options, next) ->
  db = server.plugins["hapi-mongoose"].connection
  mongoose = server.plugins["hapi-mongoose"].lib
  Schema = mongoose.Schema
  # entry init
  groupSchema = new Schema groupModel
  Group = db.model "group", groupSchema
  coreSchema = new Schema coreModel
  Core = db.model "core", coreSchema
  analogSchema = new Schema analogModel
  Analog = db.model "analog", analogSchema

  # groups
  server.route
    method: "GET"
    path: "/groups"
    handler: (req, res) ->
      # 查询数据库
      Group.find {} , {"_id": 0,"__v": 0}
      .then (result) ->
        res result
      .catch (err) ->
        console.error err
        res Boom.wrap err

  server.route
    method: ["PUT","DELETE"]
    path: "/groups/{id}"
    handler: (req, res) ->
      id = req.params.id
      findOpts =
          "id": id
      method = req.raw.req.method
      if method is "PUT"
        # 更新
        Group.update findOpts, $set: req.payload
        .then (result) ->
          if result.n is 0
            return res Boom.notFound()
          res "result": "success"
        .catch (err) ->
          console.error err
          res Boom.wrap err
      else
        # 删除
        Group.remove findOpts
        .then (result) ->
          if result.n is 0
            return res Boom.notFound()
          res "result": "success"
        .catch (err) ->
          console.error err
          res Boom.wrap err

  # cores
  server.route
    method: ["GET","POST"]
    path: "/groups/{gid}/cores"
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
        console.log findOpts
        #查询 group
        Group.find "id": gid
        .then (result) ->
          if result.length isnt 0
            Core.find findOpts
            .then (result) ->
              console.log result
              # 精确查询到结果
              if result.length isnt 0
                contains = _.pluck result , "id"
                analogs = _.union _.flatten _.pluck result , "analogs"
                resObj =
                  "existed": true
                  "contains": contains
                  "analogs": if _.isEmpty analogs[0] then [] else analogs
                findContains =
                  "group_id": gid
                console.log findContains isnt "*"
                if findContains isnt "*"
                  findContains.id = new RegExp ".*#{search}.*"
                Core.find findContains
                .then (result) ->
                  resObj.contains = _.extend resObj.contains , _.pluck result , "id"
                  res resObj
              # 没有精确查询到结果
              else
                findContains =
                  "group_id": gid
                  "id": if search isnt "*" then new RegExp ".*#{search}.*" else ""
                Core.find findContains
                .then (result) ->
                  resObj =
                    "existed": false
                    "contains": _.pluck result , "id"
                    "analogs": []
                  res resObj
          else
            # 插入groups
            group = new Group
              "id": gid
              "descr":""
            group.save()
            .then (result) ->
              resObj =
                "existed": false
                "contains": []
                "analogs": []
              res resObj
        .catch (err) ->
          console.error err
          res Boom.wrap err
      else
        # 添加
        saveArr = _.map req.payload , (data) ->
          "group_id": gid, "id": data
        taskLists = []
        _.each saveArr, (arr) ->
          task = new Promise (reslove, reject) ->
            Core.find arr
            .then (result) ->
              if result.length > 0
                return reslove "success"
              else
                core = new Core arr
                return core.save()
            .then (result) ->
              reslove "success"
            .catch (err) ->
              console.error err
              reject err
          taskLists.push task

        Promise.all taskLists
        .then () ->
          console.log "taskLists save done"
          res "result": "success"
        .catch (err) ->
          console.error err
          res Boom.wrap err

  server.route
    method: ["GET","DELETE"]
    path: "/groups/{gid}/cores/{id}"
    handler: (req, res) ->
      gid = req.params.gid
      id = req.params.id
      findOpts =
          "group_id": gid
          "id": id
      method = req.raw.req.method
      if method is "GET"
        # 查询
        Core.findOne findOpts, {"_id": 0,"__v": 0}
        .then (result) ->
          res result
        .catch (err) ->
          console.error err
          res Boom.wrap err
      else
        # 删除
        Core.findOne findOpts
        .then (result) ->
          analogs = result.analogs
          #移除近义词的核心词
          db.core.remove findOpts, (result) ->
            if result.n is 0
              return res Boom.notFound()
            _.each analogs, (analog) ->
              findArg =
                "group_id": gid
                "id": analog
              updateObj =
                cores: id
              Analog.update findArg, $pull: updateObj
              .then (result) ->
                console.log "result --> #{result}"
                res "result": "success"
        .catch (err) ->
          console.error err
          res Boom.wrap err

  # analogs
  server.route
    method: ["GET","POST"]
    path: "/groups/{gid}/analogs"
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
        Analog.find findOpts, {"_id": 0,"__v": 0}
        .then (result) ->
          res result
        .catch (err) ->
          console.error err
          res Boom.wrap err
      else
        # 添加
        findOpts.id = req.payload.id
        Analog.find findOpts
        .then (result) ->
          console.log result
          if result.length is 0
            analog = new Analog
              "group_id": gid
              "id": req.payload.id
              "cores": [req.payload.cores]
            analog.save()
            .then (result) ->
              console.log result
              coreFindOpts =
                "group_id": gid
                "id": req.payload.cores
              coreUpdateObj =
                "analogs": req.payload.id
              return Core.update coreFindOpts, $addToSet: coreUpdateObj
            .then (result) ->
              console.log "analogs add success"
              res "result": "success"
          else
            updateObj =
              cores: req.payload.cores
            coreFindOpts =
              "group_id": gid
              "id": req.payload.cores
            coreUpdateObj =
              "analogs": req.payload.id
            Analog.update findOpts, $addToSet: updateObj
            .then (result) ->
              return Core.find
            .then (result) ->
                if result.length isnt 0
                  Core.update coreFindOpts, $addToSet: coreUpdateObj
                  .then (result) ->
                      console.log "analogs add success"
                      res "result": "success"
                else
                  resObj =
                    "error":"#{req.payload.cores}，在核心词没有找到"
                  res resObj
                  .code 404
                  return
        .catch (err) ->
          console.error err
          res Boom.wrap err

  server.route
    method: ["GET","PUT","DELETE"]
    path: "/groups/{gid}/analogs/{id}"
    handler: (req, res) ->
      gid = req.params.gid
      id = req.params.id
      findOpts =
          "group_id": gid
          "id": id
      method = req.raw.req.method
      if method is "GET"
        # 查询
        Analog.findOne findOpts, {"_id": 0,"__v": 0}
        .then (result) ->
          res result
        .catch (err) ->
          console.error err
          res Boom.wrap err
      else if method is "PUT"
        # 修改
        uri = req.raw.req.url
        queryArgs = Url.parse(uri, true).query
        action = queryArgs.action or ""
        if action is "unlink"
          updateObj =
            cores: req.payload.core
          Analog.update findOpts, $pull: updateObj
          .then (result) ->
            if result.n is 0
              return res Boom.notFound()
            coreFindOpts =
              "group_id": gid
              "id": req.payload.core
            coreUpdateObj =
              "analogs": req.payload.id
            return Cores.update coreFindOpts, $pull: updateObj
          .then (result) ->
            console.log "update core success"
            return Analog.findOne findOpts
          .then (result) ->
            if result.cores.length is 0
              db.analog.remove findOpts
            res "result": "success"
          .catch (err) ->
            console.error err
            res Boom.wrap err
        else
          resObj =
            "error":"action is unlink"
          res resObj
          .code 404
      else
        # 删除
        db.analog.findOne findOpts
        .then (result) ->
          cores = result.cores
          #移除近义词的核心词
          return Analog.remove findOpts
        .then (result) ->
            if result.n is 0
              return res Boom.notFound()
            _.each cores, (core) ->
              findArg =
                "group_id": gid
                "id": analog
              updateObj =
                analog: id
              db.core.update findArg, $pull: updateObj, (result) ->
                console.log "result --> #{result}"
            res "result": "success"
        .catch (err) ->
          console.error err
          res Boom.wrap err

  next()

exports.register.attributes = name: "routes-synonym"
