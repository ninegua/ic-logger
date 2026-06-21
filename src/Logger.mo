import Array "mo:core/Array";
import VarArray "mo:core/VarArray";
import List "mo:core/List";
import Queue "mo:core/pure/Queue";
import Nat "mo:core/Nat";
import Option "mo:core/Option";

module {

  public type Buckets<A> = Queue.Queue<[A]>;
  public type Bucket<A> = List.List<A>;

  public type State<A> = {
    var buckets: Buckets<A>;     // Past buckets (front to back = oldest to newest)
    var num_of_buckets: Nat;     // Number of past buckets
    var bucket: Bucket<A>;       // Current bucket (front to back = oldest to newest)
    var num_of_lines: Nat;       // Number of lines in current bucket
    var start_index: Nat;        // Start index of the first message in past buckets
    bucket_size: Nat;
  };

  public type Stats = {
    start_index: Nat;
    bucket_sizes: [Nat];
  };

  public type View<A> = {
    start_index: Nat;
    messages: [A];
  };

  let BUCKET_SIZE = 5000;        // Default bucket size

  // Initialize an empty logger state with the given start_index and bucket_size.
  public func new<A>(start_index: Nat, bucket_size: ?Nat) : State<A> {
    {
      var buckets : Buckets<A> = Queue.empty();
      var num_of_buckets = 0;
      var bucket : Bucket<A> = List.empty();
      var num_of_lines = 0;
      var start_index = start_index;
      bucket_size = Option.get(bucket_size, BUCKET_SIZE);
    }
  };

  public class Logger<A>(s : State<A>) {

    // Move bucket into buckets
    public func roll_over() {
      s.buckets := Queue.pushBack(s.buckets, List.toArray(s.bucket));
      s.num_of_buckets := s.num_of_buckets + 1;
      s.bucket := List.empty();
      s.num_of_lines := 0;
    };

    // Add a set of messages to the log.
    public func append(msgs: [A]) {
       for (msg in msgs.vals()) {
         List.add(s.bucket, msg);
         s.num_of_lines := s.num_of_lines + 1;
         if (s.num_of_lines >= s.bucket_size) {
            roll_over()
         }
       }
    };

    // Return log stats, where:
    //   start_index is the first index of log message.
    //   bucket_sizes is the size of all buckets, from oldest to newest.
    public func stats() : Stats {
      let bucket_sizes = VarArray.repeat<Nat>(s.num_of_buckets + 1, 0);
      var i = s.num_of_buckets;
      bucket_sizes[i] := s.num_of_lines;
      var bs = s.buckets;
      label LOOP loop {
        switch (Queue.popBack(bs)) {
          case null { break LOOP; };
          case (?(bs_, b)) {
            i := i - 1;
            bucket_sizes[i] := b.size();
            bs := bs_;
          }
        }
      };
      { start_index = s.start_index; bucket_sizes = VarArray.toArray(bucket_sizes) }
    };

    // Return the messages between from and to indice (inclusive).
    public func view(from: Nat, to: Nat) : View<A> {
      assert(to >= from);
      let buf = List.empty<A>();
      var i = s.start_index;
      var b = s.buckets;
      label LOOP loop {
        switch (Queue.popFront(b)) {
          case null { break LOOP; };
          case (?(lines, d)) {
            let n = lines.size();
            // is there intersection between [i, i + n] and [from, to]
            if (i > to) { break LOOP; };
            if (i + n > from) {
              var k = if (i < from) { Nat.sub(from, i) } else { 0 };
              let m = if (i + n > to) { Nat.sub(to + 1, i) } else { n };
              while (k < m) {
                buf.add(lines[k]);
                k := k + 1;
              }
            };
            i := i + n;
            b := d;
          }
        }
      };
      if (i + s.num_of_lines > from and i <= to) {
        let arr : [A] = List.toArray(s.bucket);
        var k = if (i < from) { Nat.sub(from, i) } else { 0 };
        let m = if (i + s.num_of_lines > to) { Nat.sub(to + 1, i) } else { s.num_of_lines };
        while (k < m) {
          buf.add(arr[k]);
          k := k + 1;
        }
      };
      {
        start_index = if (s.start_index > from) { s.start_index } else { from };
        messages = List.toArray(buf);
      }
    };

    // Drop past buckets (oldest first).
    public func pop_buckets(num: Nat) {
      var i = 0;
      label LOOP while (i < num) {
        switch (Queue.popFront(s.buckets)) {
          case null { break LOOP };
          case (?(b, bs)) {
            s.num_of_buckets := s.num_of_buckets - 1;
            s.buckets := bs;
            s.start_index := s.start_index + b.size();
          };
        };
        i := i + 1;
      }
    }
  };
}
