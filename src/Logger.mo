import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Deque "mo:base/Deque";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

import Matchers "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import Suite "mo:matchers/Suite";
import Text "mo:base/Text";
import Iter "mo:base/Iter";

module {
  
  public type Buckets<A> = Deque.Deque<[A]>;
  public type Bucket<A> = List.List<A>;

  public type State<A> = {
    var buckets: Buckets<A>;     // Past buckets (left to right = newest to oldest)
    var num_of_buckets: Nat;     // Number of past buckets
    var bucket: Bucket<A>;       // Current bucket (tail to head = newest to oldest)
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
      var buckets : Buckets<A> = Deque.empty();
      var num_of_buckets = 0;
      var bucket : Bucket<A> = List.nil();
      var num_of_lines = 0;
      var start_index = start_index;
      bucket_size = Option.get(bucket_size, BUCKET_SIZE);
    }
  };

  // Convert a list to array (ordered from head to tail).
  public func to_array<T>(list: List.List<T>, n: Nat) : [T] {
    let buf = Buffer.Buffer<T>(n);
    var l = list;
    label LOOP loop {
      switch (List.pop(l)) {
        case (null, _) { break LOOP; };
        case (?v, l_) { buf.add(v); l := l_; }
      }
    };
    Array.tabulate<T>(n, func(i: Nat): T { buf.get(n - i - 1) })
  };

  public class Logger<A>(s : State<A>) {

    // Move bucket into buckets
    public func roll_over() {
      s.buckets := Deque.pushBack(s.buckets, to_array(s.bucket, s.num_of_lines));
      s.num_of_buckets := s.num_of_buckets + 1;
      s.bucket := List.nil();
      s.num_of_lines := 0;
    };
 
    // Add a set of messages to the log.
    public func append(msgs: [A]) {
       for (msg in msgs.vals()) {
         s.bucket := List.push(msg, s.bucket);
         s.num_of_lines := s.num_of_lines + 1;
         if (s.num_of_lines >= BUCKET_SIZE) {
            roll_over()
         }
       }
    };
 
    // Return log stats, where:
    //   start_index is the first index of log message.
    //   bucket_sizes is the size of all buckets, from oldest to newest.
    public func stats() : Stats {
      var bucket_sizes = Array.init<Nat>(s.num_of_buckets + 1, 0);
      var i = s.num_of_buckets;
      bucket_sizes[i] := s.num_of_lines;
      var bs = s.buckets;
      label LOOP loop {
        switch (Deque.popBack(bs)) {
          case null { break LOOP; };
          case (?(bs_, b)) {
            i := i - 1;
            bucket_sizes[i] := b.size();
            bs := bs_;
          }
        }
      };
      { start_index = s.start_index; bucket_sizes = Array.freeze(bucket_sizes) }
    };
 
    // Return the messages between from and to indice (inclusive).
    public func view(from: Nat, to: Nat) : View<A> {
      assert(to >= from);
      let buf = Buffer.Buffer<A>(to - from + 1);
      var i = s.start_index;
      var b = s.buckets;
      label LOOP loop {
        switch (Deque.popFront(b)) {
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
        let arr : [A] = to_array(s.bucket, s.num_of_lines); 
        var k = if (i < from) { Nat.sub(from, i) } else { 0 };
        let m = if (i + s.num_of_lines > to) { Nat.sub(to + 1, i) } else { s.num_of_lines };
        while (k < m) {
          buf.add(arr[k]);
          k := k + 1;
        }
      };
      {
        start_index = if (s.start_index > from) { s.start_index } else { from };
        messages = buf.toArray();
      }
    };
  
    // Drop past buckets (oldest first).
    public func pop_buckets(num: Nat) {
      var i = 0;
      label LOOP while (i < num) {
        switch (Deque.popFront(s.buckets)) {
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

  type Suite = Suite.Suite;
  public func test() : Suite {
    let to_array_test =
      Suite.suite("to_array", [
        Suite.test("empty",
          to_array<Nat>(List.nil(), 0), 
          Matchers.equals(T.array<Nat>(T.natTestable, []))),
        Suite.test("singleton",
          to_array<Nat>(List.push(1, List.nil()), 1), 
          Matchers.equals(T.array<Nat>(T.natTestable, [1]))),
        Suite.test("multiple",
          to_array<Nat>(List.push(2, List.push(1, List.nil())), 2), 
          Matchers.equals(T.array<Nat>(T.natTestable, [1, 2]))),
        Suite.test("truncated to size",
          to_array<Nat>(List.push(3, List.push(2, List.push(1, List.nil()))), 2), 
          Matchers.equals(T.array<Nat>(T.natTestable, [2, 3]))),
      ]);

    let N = 10;
    let S = 3;
    let logger = Logger<Nat>(new(0, ?S));
    let append_test = Suite.suite("append", 
      Array.tabulate<Suite>(N, func(n: Nat): Suite {
        logger.append([n]);
        Suite.test(Text.concat("append/", Nat.toText(n)),
          logger.view(0, n).messages,
          Matchers.equals(T.array<Nat>(T.natTestable, 
            Array.tabulate<Nat>(n + 1, func(x: Nat): Nat { x }))))
      }));

    let view_tests = Buffer.Buffer<Suite>(0);
    for (i in Iter.range(0, N - 2)) {
      for (j in Iter.range(i, N - 1)) {
        view_tests.add(
          Suite.test(Text.join("/", Iter.fromArray(["view", Nat.toText(i), Nat.toText(j)])),
            logger.view(i, j).messages,
            Matchers.equals(T.array<Nat>(T.natTestable, 
              Array.tabulate(Nat.sub(j+1, i), func(x: Nat): Nat { x + i })))));
      };
    };
    let view_test = Suite.suite("view", view_tests.toArray());

    let view_tests_after_pop = Buffer.Buffer<Suite>(0);
    for (k in Iter.range(1,2)) {
      logger.pop_buckets(1);
      for (i in Iter.range(0, N - 2)) {
        for (j in Iter.range(i, N - 1)) {
          view_tests.add(
            Suite.test(Text.join("/", Iter.fromArray(["view", Nat.toText(i), Nat.toText(j)])),
              logger.view(i, j).messages,
              Matchers.equals(T.array<Nat>(T.natTestable, 
                if (j + 1 > k * S) {
                  Array.tabulate(Nat.sub(j+1, Nat.max(i, S)), func(x: Nat): Nat { x + i })
                } else { [] }
              ))))
        }
      }
    };
    let view_test_after_pop = Suite.suite("view", view_tests_after_pop.toArray());

    Suite.suite("Test Logger", [ to_array_test, append_test, view_test, view_test_after_pop ])
  }
}
