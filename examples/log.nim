import nimcrate
crate:
    id = "jjv360.nimcrate.console-log"
    name = "Console Log Example"
    description = "This simple app just logs a message to the console. To build: `nimcrate examples/log.nim`"


# App code
import std/strformat
import std/tables
echo fmt"""Hello world from {NimCrateInfo["name"]} version {NimCrateInfo["version"]}!"""