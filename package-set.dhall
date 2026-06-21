[
  { name = "base"
  , version = "646e5f3edb6f400bc71db9991da7a81b8bc175f9"
  , repo = "https://github.com/dfinity/motoko-base.git"
  , dependencies = [ ] : List Text
  },
  { name = "core"
  , version = "1b6e4995e730b5f152106e64d943ae0cc0aa117b"
  , repo = "https://github.com/caffeinelabs/motoko-core"
  , dependencies = [] : List Text
  },
  { name = "matchers"
  , version = "3dac8a071b69e4e651b25a7d9683fe831eb7cffd"
  , repo = "https://github.com/kritzcreek/motoko-matchers.git"
  , dependencies = [ "base" ] : List Text
  }
]
