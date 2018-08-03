const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Queue = std.atomic.Queue;

// ActorInterface is a member of all Actor's and
// every Actor must implement processMessage who's
// address is saved in this interface.
pub const ActorInterface = packed struct {
    pub processMessage: fn (actorInterface: *ActorInterface, msg: *Message) void,
};

// Actor that can process messages
pub fn Actor(comptime BodyType: type) type {
    return packed struct {
        const Self = this;

        pub interface: ActorInterface,
        pub body: BodyType,

        pub fn init() Self {
            var self: Self = undefined;
            //warn("Actor.init: aiPtr={*} self={*}\n", &self.interface, &self);
            self.interface.processMessage = BodyType.processMessage;
            BodyType.init(&self);
            return self;
        }

        /// Return a pointer to the Actor this interface is a member of.
        pub fn getActorPtr(aiPtr: *ActorInterface) *Self {
            return @fieldParentPtr(Self, "interface", aiPtr);
        }
    };
}

// Dispatches messages to actors
pub fn ActorDispatcher(comptime maxActors: usize) type {
    return struct {
        const Self = this;

        pub queue: Queue(*Message),
        pub msg_count: u64,
        pub last_msg_cmd: u64,
        pub actor_processMessage_count: u64,

        // What type should ActorPtr be or how do I cast it
        // so I can call actor.processMessage
        pub actors: [maxActors]*ActorInterface,
        pub actors_count: u64,

        pub fn init() Self {
            return Self {
                .queue = Queue(*Message).init(),
                .msg_count = 0,
                .last_msg_cmd = 0,
                .actor_processMessage_count = 0,
                .actors_count = 0,
                .actors = undefined,
            };
        }

        /// NOT thread safe
        pub fn add(self: *Self, actorInterface: *ActorInterface) !void {
            if (self.actors_count >= self.actors.len) return error.TooManyActors;
            self.actors[self.actors_count] = actorInterface;
            self.actors_count += 1;
        }

        pub fn broadcastLoop(self: *Self) void {
            while (true) {
                var pMsgNode = self.queue.get() orelse return;
                self.msg_count += 1;
                self.last_msg_cmd = pMsgNode.data.cmd;
                for (self.actors) |aiPtr| {
                    self.actor_processMessage_count += 1;
                    aiPtr.processMessage(aiPtr, pMsgNode.data);
                }
            }
        }
    };
}

// A message
pub const Message = struct {
    pub cmd: u64,
};

// An ActorBody
const MyActorBody = packed struct {
    const Self = this;

    pub count: usize,

    pub fn init(self: *Actor(MyActorBody)) void {
        self.body.count = 0;
    }

    pub fn processMessage(aiPtr: *ActorInterface, msg: *Message) void {
        //var self = @fieldParentPtr(Self, "interface", aiPtr);
        var self = Actor(MyActorBody).getActorPtr(aiPtr);
        //warn("processMessage: aiPtr={*} self={*}\n", aiPtr, self);
        self.body.count += msg.cmd;
    }
};

test "Actor" {
    // Create an actor
    var myActor = Actor(MyActorBody).init();
    assert(myActor.body.count == 0);

    // Create a message
    var msg = Message { .cmd = 123 };
    assert(msg.cmd == 123);

    // Test that the actor works
    myActor.interface.processMessage(&myActor.interface, &msg);
    assert(myActor.body.count == 1 * 123);
    myActor.interface.processMessage(&myActor.interface, &msg);
    assert(myActor.body.count == 2 * 123);

    // Create a dispatcher
    var dispatcher = ActorDispatcher(1).init();
    assert(dispatcher.msg_count == 0);

    // Add the actor
    try dispatcher.add(&myActor.interface);

    // Create a node with a pointer to a message
    var node0 = @typeOf(dispatcher.queue).Node {
        .data = &msg,
        .next = undefined,
    };

    // Place the node on the queue and broadcast to the actors
    dispatcher.queue.put(&node0);
    dispatcher.broadcastLoop();
    assert(dispatcher.last_msg_cmd == 123);
    assert(dispatcher.msg_count == 1);
    assert(dispatcher.actor_processMessage_count == 1);
    assert(myActor.body.count == 3 * 123);
}
