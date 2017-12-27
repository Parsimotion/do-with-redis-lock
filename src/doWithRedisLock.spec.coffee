_ = require "lodash"
Promise = require "bluebird"
should = require "should"

_.assign process.env, {
  REDIS_PORT: 6379
  REDIS_HOST: "localhost"
  REDIS_AUTH: ""
}

KEY = "aKey"

describe "#doWithRedisLock", ->

  doWithRedisLock = require "./doWithRedisLock"
  doSomeWithLock = -> doWithRedisLock _.constant(Promise.resolve().delay(500)), KEY


  it "should execute a command", ->
    doSomeWithLock()

  it "should execute a command if previous operation is done", ->
    doSomeWithLock().then -> doSomeWithLock()

  it "should fail if the resource is locked", ->
    doSomeWithLock()
    doSomeWithLock().should.be.rejectedWith { statusCode: 503 }