# IC Logger

This [motoko] library provides a module to help create an append-only logger actor.

## Usage

You can use this library with the [vessel] package manager.
A sample usage of creating a logger actor (or canister) from the [Logger](./src/Logger.mo) module can be found in the [example](./example/) sub-directory.
You'll need both [dfx] and [vessel] in PATH before trying it out:

```
cd example
dfx deploy
```

It creates a text-based logger and gives the controller a few privileged methods to use it.
[Its actor interface](./example/TextLogger.did) is given in [candid]:

```
type View = 
 record {
   messages: vec text;
   start_index: nat;
 };
type Stats = 
 record {
   bucket_sizes: vec nat;
   start_index: nat;
 };
service : {
   allow: (vec principal) -> () oneway; // Allow some canisters to call the `append` method.
   append: (vec text) -> () oneway;     // Append a set of new log entries.
   pop_buckets: (nat) -> () oneway;     // Remove the given number of oldest buckets.
   stats: () -> (Stats) query;          // Get the latest logger stats.
   view: (nat, nat) -> (View) query;    // View logs in the given index interval (inclusive).
}
```

## Functionality

1. The logger actor provides a single `append` method for other actors to call.
2. The logger will keep all past logs in the order as they were received, and every logline has an index or line number.
   These logs are stored in "buckets", and when a bucket is full, the next bucket is created.
   Buckets are also numbered, and the capacity of a bucket is configurable when initializing the `Logger` class.
3. The controller can perform some adminstrative duties, such as changing which canisters are allowed to call `append`, or remove old buckets to save some space.
4. When an old bucket is removed, it does not change the index of log lines. This means querying logs using `view(..)` should given consistent results (unless they are removed).

## Tips

Something I find very useful when doing logging is to keep track of "sessions".
Due to the nature of async programming, calls may be intertwined, so are the log messages they produce.
This makes it hard to figure out what is going on in different threads (or "sessions") of execution.

Here is a helper function I use to solve this problem:

```
func logger(name: Text) : Text -> async () {
  let prefix = "[" # Int.toText(Time.now()) # "/";
  func(s: Text) : async () {
      Logger.append([prefix # Int.toText(Time.now() / 1_000_000_000) # "] " # name # ": " # s])
  }
};
```

Calling `logger("some name")` will return a function that can be used to do the actual logging.
The interesting bit is that we use the timestamp at the creation of this logger as a prefix to help distinguish "sessions" that span across `await` statements.

Here are some example log entries from [tipjar]:

```
"[1642195271679220110/1642195271] heartbeat: BeforeCheck {canister = rkp4c-7iaaa-aaaaa-aaaca-cai}"
"[1642195271679220110/1642195271] heartbeat: AfterCheck {cycle = 90_000_000_000_000}"
"[1642195271062468878/1642195272] heartbeat: AfterCheck {cycle = 100_000_000_000_000}"
"[1642198872792672023/1642198872] heartbeat: BeforeCheck {canister = rno2w-sqaaa-aaaaa-aaacq-cai}"
"[1642198873407808427/1642198873] heartbeat: BeforeCheck {canister = rkp4c-7iaaa-aaaaa-aaaca-cai}"
"[1642198873407808427/1642198873] heartbeat: AfterCheck {cycle = 90_000_000_000_000}"
"[1642198872792672023/1642198874] heartbeat: AfterCheck {cycle = 100_000_000_000_000}"
```

It has a `heartbeat` method that logs `BeforeCheck` and `AfterCheck`.
These entries are ordered by when the Logger receives the `append` call.
We can see that `1642198872792672023` has two entries that do not appear next to each other.
And yet we can still tell they are from the same "session" because of the common prefix.

## Development

The code is documented inline and unit tests are provided.
If you have installed a [nix] environment, you can run the tests like this:

```
nix-shell
cd test
make
```

[motoko]: https://github.com/dfinity/motoko
[vessel]: https://github.com/dfinity/vessel
[candid]: https://github.com/dfinity/candid
[dfx]: https://github.com/dfinity/sdk
[nix]: https://github.com/NixOS/nix
[tipjar]: https://github.com/ninegua/tipjar
