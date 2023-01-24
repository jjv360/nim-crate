# Package
version       = "0.1.0"
author        = "jjv360"
description   = "Package your Nim app for different platforms"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim", "html", "zip"]
bin           = @["nimcrate"]

# Dependencies
requires "nim >= 1.4.0"
requires "classes >= 0.2.13"
requires "plists >= 0.2.0"

# Task to build and run the sample app
task exampleAlert, "Run Example: Alert":
    exec "nimble install -y"
    exec "nimcrate examples/alert.nim --run"

# Test task
task test, "Test":
    exec "nimble install -y"
    rmDir("dist")

    # Test config output
    echo ""
    echo "Testing config output..."
    exec "nimcrate examples/log.nim --outputConfig"

    # Test building a crate with no info
    echo ""
    echo "Testing infoless crate..."
    exec "nimcrate examples/log.nim"

    # Test building a crate with info
    echo ""
    echo "Testing crate..."
    exec "nimcrate examples/alert.nim"