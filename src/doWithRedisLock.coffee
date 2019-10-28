_ = require "lodash"
Promise = require "bluebird"
Redis = require "ioredis"
Redlock = require "redlock"
debug = require("debug") "do-with-redis-lock"
LockError = Redlock.LockError
redis = null

setRedis = ({ port, host, auth, db }) ->
  redis = -> Promise.promisifyAll(
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

connected = (options) ->
  redlock =  new Redlock [ redis() ], _.merge({ retryCount: 0 }, options)
  execute: (command, key, expire) ->
    Promise.using redlock.disposer(key, expire), (lock) -> command()
    .catch LockError, ->
      debug "locked resource #{ key }"
      throw
        statusCode: options.lockedStatusCode or 503
        body:
          code: "concurrency_conflict"
          message: "Somebody is doing this at the same time at you"
  

module.exports = (connection) -> 
  if connection? and redisIsConfigured(connection) then setRedis(connection) else throw new Error "Missing connection credentials"
  (command, key, expire = 120, options = {}) ->
    connected(options).execute command, key, expire * 1000
