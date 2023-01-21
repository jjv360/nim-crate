# Package
version       = "0.1.0"
author        = "jjv360"
description   = "Package your Nim app for different platforms"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim", "html"]
bin           = @["nimcrate"]

# Dependencies
requires "nim >= 1.4.0"

# Test task
task test, "Test":
    exec "nimble install -y"
    exec "nimcrate examples/alert.nim"