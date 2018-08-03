# Zig Actor

Create an Actor that processes messages.

Currently the type ActorPtr is \*@OpaqueType as it represents any possible
type of Actor. But as it's an opaque pointer it needs to be cast or a
different type so I can call "actor.processMessage" in the broadcastLoop.

## Test
```bash
$ zig test actor.zig
```

## Clean
Remove `zig-cache/` directory
```bash
$ rm -rf ./zig-cache/
```
