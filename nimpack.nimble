# Package
version       = "0.1.0"
author        = "jjv360"
description   = "Package your Nim app for different platforms"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim", "html"]
bin           = @["nimpack"]

# Dependencies
requires "nim >= 1.4.0"
requires "classes >= 0.2.0"
requires "docopt"
requires "elvis"