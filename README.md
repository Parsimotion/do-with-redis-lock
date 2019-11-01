# do-with-redis-lock

## usage

```coffee
redisConn = {
  port: 9000,
  host: "...",
  auth: "...",
  db: 1 #optional
}
```

```coffee
doWithLock = require("do-with-redis-lock")(redisConn)

action = ->
  request.getAsync(...) # something that returns a Promise

doWithLock(action, key).then (result) ->
  # continue...
```

If a concurrency problem appears, the *Promise* is rejected with:
```js
{
  statusCode: 503,
  body: {
    code: "concurrency_conflict",
    message: "Somebody is doing this at the same time at you"
  }
}
```

## migration

### 1.x users
- In 2.x, the *Promise*'s rejection reason isn't `"concurrency_conflict"` anymore. See above.

### 2.x users
- In 3.x, the connection credentials are no longer environment variables. They are passed by parameters instead. See above.