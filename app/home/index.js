// Generated by CoffeeScript 1.10.0
var Good, Hapi, mongojs, registerArr, server;

require("source-map-support").install();

Hapi = require("hapi");

Good = require("good");

mongojs = require("mongojs");

server = new Hapi.Server();

server.connection({
  port: 3000
});

if (process.env.NODE_ENV === "production") {
  server.app.db = mongojs("db:27017/local", ["words", "group", "core", "analog"]);
} else {
  server.app.db = mongojs("192.168.59.103:27017/local", ["words", "group", "core", "analog"]);
}

registerArr = [
  {
    register: require("./searchrec"),
    options: {}
  }, {
    register: require("./synonym"),
    options: {}
  }, {
    register: Good,
    options: {
      reporters: {
        console: [
          {
            module: "good-squeeze",
            name: "Squeeze",
            args: [
              {
                response: "*",
                log: "*"
              }
            ]
          }, {
            module: "good-console"
          }, "stdout"
        ]
      }
    }
  }
];

server.register(registerArr, function(err) {
  if (err) {
    console.error(err);
    throw err;
  }
  return server.start(function(err) {
    if (err) {
      throw err;
    }
    return console.log("Server is running at:" + server.info.uri);
  });
});
