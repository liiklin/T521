// Generated by CoffeeScript 1.10.0
var Boom, Url, searchrecPath;

Boom = require('boom');

Url = require("url");

searchrecPath = "searchrec";

exports.register = function(server, options, next) {
  var db;
  db = server.app.db;
  server.route({
    method: "GET",
    path: "/" + searchrecPath + "/groups/{gid}/words",
    handler: function(req, res) {
      var findOpts, gid, queryArgs, state, top, uri;
      uri = req.raw.req.url;
      queryArgs = Url.parse(uri, true).query;
      gid = req.params.gid;
      top = Number(queryArgs.top || "20");
      state = queryArgs.state || "";
      findOpts = {
        "group_id": gid,
        "times": {
          $gt: top
        }
      };
      if (state !== "") {
        findOpts.state = state;
      }
      return db.words.find(findOpts, {
        "_id": 0
      }, function(err, result) {
        if (err) {
          return res(Boom.wrap(err, "Internal MongoDB error"));
        }
        return res(result);
      });
    }
  });
  server.route({
    method: ["PUT", "DELETE"],
    path: "/" + searchrecPath + "/groups/{gid}/words/{id}",
    handler: function(req, res) {
      var findOpts, gid, id, method;
      gid = req.params.gid;
      id = req.params.id;
      findOpts = {
        "group_id": gid,
        "id": id
      };
      method = req.raw.req.method;
      if (method === "PUT") {
        return db.words.update(findOpts, {
          $set: req.payload
        }, function(err, result) {
          if (err) {
            return res(Boom.wrap(err, "Internal MongoDB error"));
          }
          if (result.n === 0) {
            return res(Boom.notFound());
          }
          return res({
            "result": "success"
          });
        });
      } else {
        return db.words.remove(findOpts, function(err, result) {
          if (err) {
            return res(Boom.wrap(err, "Internal MongoDB error"));
          }
          if (result.n === 0) {
            return res(Boom.notFound());
          }
          return res({
            "result": "success"
          });
        });
      }
    }
  });
  return next();
};

exports.register.attributes = {
  name: "routes-" + searchrecPath
};

//# sourceMappingURL=searchrec.js.map
