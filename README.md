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

doWithLock(action, key)
  .then (result) ->
    # all is good
  .catch (e) ->
    if (e is "concurrency_conflict")
      # handle error
    # other bad thing happened
```
