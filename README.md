# Zig Actor

Actors are independent components of computation. In the
typical usage actors communicate via messages and do not
share any data. [See Actor Model](https://en.wikipedia.org/wiki/Actor_model)
for more information.

A key to the implementation was to create an `ActorInterface` as suggested
by MajorLag on IRC, https://irclog.whitequark.org/zig/2018-08-03#22735193.

## Test
```bash
$ zig test actor.zig
Test 1/1 Actor...OK
All tests passed.
```

## Clean
Remove `zig-cache/` directory
```bash
$ rm -rf ./zig-cache/
```
