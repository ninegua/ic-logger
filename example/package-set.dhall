let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.18-20220107/package-set.dhall
let additions = [
      { name = "ic-logger"
      , repo = "https://github.com/ninegua/ic-logger"
      , version = "95e43be3fcc285121b5bb1357bfd617efc2b2234"
      , dependencies = [ "base" ]
      }
    ]
in  upstream # additions
