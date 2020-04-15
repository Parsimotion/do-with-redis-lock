_ = require "lodash"
Promise = require "bluebird"
should = require "should"

redisConn = {
  port: 6379
  host: "localhost"
  auth: ""
  connectionName: "anita"
}

KEY = "aKey"

describe "#doWithRedisLock", ->

  doWithRedisLock = require("./doWithRedisLock")(redisConn)
  doSomeWithLock = (options) -> doWithRedisLock _.constant(Promise.resolve().delay(500)), KEY, 120, options

  it "should execute a command", ->
    doSomeWithLock()

  it "should execute a command if previous operation is done", ->
    doSomeWithLock().then -> doSomeWithLock()

  it "should fail if the resource is locked", ->
    doConcurrently [doSomeWithLock(), doSomeWithLock()]
    .then ([ firstOperation, secondOperation ]) =>
      firstOperation.isFulfilled().should.be.true()
      secondOperation.isFulfilled().should.be.false()

  it "should retry if retrying is configured", ->
    doConcurrently [doSomeWithLock(), doSomeWithLock({ retryCount: 2, retryDelay: 500 })]
    .then (operations) ->
      operations.should.matchEach (operation) -> operation.isFulfilled().should.be.true()

doConcurrently = (promises) ->
  Promise.all promises.map (it) -> it.reflect()
