# do-with-redis-lock

Usage:

```bash
export REDIS_PORT="..."
export REDIS_HOST="..."
export REDIS_AUTH="..."
export REDIS_DB="..."
```

```coffee
doWithLock = require("do-with-redis-lock")

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
