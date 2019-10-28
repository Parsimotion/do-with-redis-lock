_ = require "lodash"
Promise = require "bluebird"
Redis = require "ioredis"
Redlock = require "redlock"
debug = require("debug") "do-with-redis-lock"
LockError = Redlock.LockError

redis = ({ port, host, auth, db }) ->
  Promise.promisifyAll(
    new Redis
      port: port
      host: host
      family: 4
      password: auth
      db: db or 1
  )

redisIsConfigured = ({ port, host, auth }) ->
  port? and
  host? and
  auth?

disconnected = ->
  execute: -> throw new Error "Missing connection credentials"

connected = (connection, options) ->
  redlock =  new Redlock [ redis(connection) ], _.merge({ retryCount: 0 }, options)
  execute: (command, key, expire) ->
    Promise.using redlock.disposer(key, expire), (lock) -> command()
    .catch LockError, ->
      debug "locked resource #{ key }"
      throw
        statusCode: options.lockedStatusCode or 503
        body:
          code: "concurrency_conflict"
          message: "Somebody is doing this at the same time at you"
  

module.exports = (connection) -> (command, key, expire = 120, options = {}) ->
  actualState = if connection? and redisIsConfigured(connection) then connected(connection, options) else disconnected()
  actualState.execute command, key, expire * 1000
