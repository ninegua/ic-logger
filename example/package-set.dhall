let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.18-20220107/package-set.dhall
let additions = [
      { name = "ic-logger"
      , repo = "https://github.com/ninegua/ic-logger"
      , version = "95e06542158fc750be828081b57834062aa83357"
      , dependencies = [ "base" ]
      }
    ]
in  upstream # additions
