// Persistent logger keeping track of what is going on.

import Array "mo:core/Array";
import Option "mo:core/Option";

import Logger "mo:ic-logger/Logger";

shared(msg) persistent actor class TextLogger() {
  transient let OWNER = msg.caller;

  let state : Logger.State<Text> = Logger.new<Text>(0, null);
  transient let logger = Logger.Logger<Text>(state);

  // Principals that are allowed to log messages.
  var allowed : [Principal] = [OWNER];

  // Set allowed principals.
  public shared (msg) func allow(ids: [Principal]) : () {
    assert(msg.caller == OWNER);
    allowed := ids;
  };

  // Add a set of messages to the log.
  public shared (msg) func append(msgs: [Text]) : () {
    assert(Option.isSome(Array.find(allowed, func (id: Principal) : Bool { msg.caller == id })));
    logger.append(msgs);
  };

  // Return log stats, where:
  //   start_index is the first index of log message.
  //   bucket_sizes is the size of all buckets, from oldest to newest.
  public query func stats() : async Logger.Stats {
    logger.stats()
  };

  // Return the messages between from and to indice (inclusive).
  public shared query (msg) func view(from: Nat, to: Nat) : async Logger.View<Text> {
    assert(msg.caller == OWNER);
    logger.view(from, to)
  };

  // Drop past buckets (oldest first).
  public shared (msg) func pop_buckets(num: Nat) : () {
    assert(msg.caller == OWNER);
    logger.pop_buckets(num)
  }
}
