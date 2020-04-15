_ = require "lodash"
Promise = require "bluebird"
Redis = require "ioredis"
Redlock = require "redlock"
debug = require("debug") "do-with-redis-lock"
LockError = Redlock.LockError

setRedis = ({ port, host, auth, db, connectionName }) ->
  redisGetter = -> Promise.promisifyAll(
    new Redis { port, host, connectionName, family: 4, password: auth, db: db or 1 }
   )
  _.memoize redisGetter, JSON.stringify

redisIsConfigured = ({ port, host, auth }) ->
  port? and
  host? and
  auth?

connected = (redis, options) ->
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
  if connection? and redisIsConfigured(connection) then redis = setRedis(connection) else throw new Error "Missing connection credentials"
  (command, key, expire = 120, options = {}) ->
    connected(redis, options).execute command, key, expire * 1000
