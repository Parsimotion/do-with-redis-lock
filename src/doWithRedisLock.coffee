Promise = require("bluebird")
Redis = require("ioredis")
_ = require "lodash"

redis = _.once -> new Redis
  port: process.env.REDIS_PORT
  host: process.env.REDIS_HOST
  family: 4
  password: process.env.REDIS_AUTH
  db: process.env.REDIS_DB or 1

redisIsConfigured = ->
  process.env.REDIS_PORT? and
  process.env.REDIS_HOST? and
  process.env.REDIS_AUTH?

module.exports = (getPromise, key, expire = 120) ->
  return getPromise() if not redisIsConfigured()

  client = redis()
  new Promise (resolve, reject) ->
    client.set key, "locked", "EX", expire, "NX", (err, created) ->
      if err? or not created?
        return reject
          statusCode: 503
          body:
            code: "concurrency_conflict"
            message: "Somebody is doing this at the same time at you"

      getPromise()
      .then (response) ->
        resolve response
      .catch (err) ->
        reject err
      .finally ->
        client.del key
