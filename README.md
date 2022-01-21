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
