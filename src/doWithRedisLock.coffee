Promise = require("bluebird")
Redis = require("ioredis")
_ = require "lodash"

redis = _.once -> new Redis
  port: process.env.REDIS_PORT
  host: process.env.REDIS_HOST
  family: 4
  password: process.env.REDIS_AUTH
  db: process.env.REDIS_DB or 1

module.exports = (getPromise, key, expire = 120) ->

  new Promise (resolve, reject) ->
    redis().set key, "locked", "EX", expire, "NX", (err, created) ->
      return reject "concurrency_conflict" if err? or not created?

      getPromise()
      .then (response) ->
        resolve response
      .catch (err) ->
        reject err
      .finally ->
        redis.del key
