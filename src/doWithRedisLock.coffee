_ = require "lodash"
Promise = require "bluebird"
Redis = require "ioredis"
Redlock = require "redlock"
LockError = Redlock.LockError

redis = ->
  Promise.promisifyAll(
    new Redis
      port: process.env.REDIS_PORT
      host: process.env.REDIS_HOST
      family: 4
      password: process.env.REDIS_AUTH
      db: process.env.REDIS_DB or 1
  )

redisIsConfigured = ->
  process.env.REDIS_PORT? and
  process.env.REDIS_HOST? and
  process.env.REDIS_AUTH?

disconnected = ->
  execute: (command) -> command()

connected = () ->
  redlock =  new Redlock [ redis() ], retryCount: 0
  execute: (command, key, expire) ->
    Promise.using redlock.disposer(key, expire), (lock) -> command()
    .catch LockError, ->
      throw
        statusCode: 503
        body:
          code: "concurrency_conflict"
          message: "Somebody is doing this at the same time at you"

actualState = if redisIsConfigured() then connected() else disconnected()

module.exports = (command, key, expire = 120) -> actualState.execute command, key, expire * 1000