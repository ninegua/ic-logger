import Logger "../src/Logger";

import Array "mo:core/Array";
import List "mo:core/List";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Nat "mo:core/Nat";

import Matchers "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import Suite "mo:matchers/Suite";


type Suite = Suite.Suite;
func test() : Suite {
  let N = 10;
  let S = 3;
  let logger = Logger.Logger<Nat>(Logger.new(0, ?S));
  let append_test = Suite.suite("append",
    Array.tabulate<Suite>(N, func(n: Nat): Suite {
      logger.append([n]);
      Suite.test(Text.concat("append/", Nat.toText(n)),
        logger.view(0, n).messages,
        Matchers.equals(T.array<Nat>(T.natTestable,
          Array.tabulate<Nat>(n + 1, func(x: Nat): Nat { x }))))
    }));

  let view_tests = List.empty<Suite>();
  for (i in Nat.range(0, N - 1)) {
    for (j in Nat.range(i, N)) {
      view_tests.add(
        Suite.test(Text.join(Iter.fromArray(["view", Nat.toText(i), Nat.toText(j)]), "/"),
          logger.view(i, j).messages,
          Matchers.equals(T.array<Nat>(T.natTestable,
            Array.tabulate(Nat.sub(j+1, i), func(x: Nat): Nat { x + i })))));
    };
  };
  let view_test = Suite.suite("view", List.toArray(view_tests));

  let view_tests_after_pop = List.empty<Suite>();
  for (k in Nat.range(1,3)) {
    logger.pop_buckets(1);
    for (i in Nat.range(0, N - 1)) {
      for (j in Nat.range(i, N)) {
        view_tests.add(
          Suite.test(Text.join(Iter.fromArray(["view", Nat.toText(i), Nat.toText(j)]), "/"),
            logger.view(i, j).messages,
            Matchers.equals(T.array<Nat>(T.natTestable,
              if (j + 1 > k * S) {
                Array.tabulate(Nat.sub(j+1, Nat.max(i, S)), func(x: Nat): Nat { x + i })
              } else { [] }
            ))))
      }
    }
  };
  let view_test_after_pop = Suite.suite("view", List.toArray(view_tests_after_pop));

  Suite.suite("Test Logger", [ append_test, view_test, view_test_after_pop ])
};

Suite.run(test())
