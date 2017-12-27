Promise = require("bluebird")
Redis = require("ioredis")
_ = require "lodash"

redis = ->
  Promise.promisifyAll
    new Redis
      port: process.env.REDIS_PORT
      host: process.env.REDIS_HOST
      family: 4
      password: process.env.REDIS_AUTH
      db: process.env.REDIS_DB or 1

redisIsConfigured = ->
  process.env.REDIS_PORT? and
  process.env.REDIS_HOST? and
  process.env.REDIS_AUTH?

disconnected = ->
  execute: (command) -> command()

connected = (client) ->
  execute: (command, key, expire) ->    
    client.setAsync key, "locked", "EX", expire, "NX"
    .tap (created) -> throw "locked resource" unless created?
    .catch -> 
      throw
        statusCode: 503
        body:
          code: "concurrency_conflict"
          message: "Somebody is doing this at the same time at you"
    .then -> 
      command().finally -> client.delAsync key

actualState = if redisIsConfigured() then connected(redis()) else disconnected()

module.exports = (command, key, expire = 120) -> actualState.execute command, key, expire