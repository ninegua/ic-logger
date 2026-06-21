[
  { name = "core"
  , version = "1b6e4995e730b5f152106e64d943ae0cc0aa117b"
  , repo = "https://github.com/caffeinelabs/motoko-core"
  , dependencies = [] : List Text
  },
  { name = "ic-logger"
  , repo = "https://github.com/ninegua/ic-logger"
  , version = "6602739843dcf58278a8e79204232b46c2a7a155"
  , dependencies = [ "core" ]
  }
]
