import std/os
import std/osproc
import std/strutils
import std/parseopt
import std/tables
import std/terminal
import std/tempfiles
import std/exitprocs
import std/json
import ./platform_windows
import ./platform_web

# Execute process and return the exit code
proc run(args: varargs[string]): tuple[output: string, exitCode: int] =
    let cmd = args.quoteShellCommand()
    # echo "Run: " & cmd
    return execCmdEx(cmd, { poStdErrToStdOut })



## Build a specific target
proc buildTarget(target: string, config: Table[string, string]) =

    # Get platform ID
    var platformID = target
    let idx = platformID.find(":")
    if idx >= 0:
        platformID = platformID.substr(0, idx-1)

    # Start building
    stdout.styledWriteLine(fgBlue, "> ", fgDefault, "Building target: ", target)

    # Build for the associated platform
    if platformID == "windows": 
        buildWindows(target, config)
    elif platformID == "web": 
        buildWeb(target, config)
    else: 
        stdout.styledWriteLine(fgYellow, "  ! ", fgDefault, "Skipping due to unknown platform: " & platformID)


## Get package version from .nimble file
proc getNimbleVersion(): string =

    # Catch errors
    try:

        # Get it
        let result2 = run("nimble", "dump", "--json")
        let json = parseJson(result2.output)
        return json["version"].getStr()

    except:

        # Couldn't get it, use a default version
        return "0.0.1"


# Entry point
proc run2() =

    # Get command line arguments
    var p = initOptParser()
    var filename = ""
    var options: Table[string, string]
    while true:
        p.next()
        case p.kind
            of cmdEnd: break
            of cmdShortOption, cmdLongOption:
                if p.val == "":
                    options[p.key] = "1"
                else:
                    options[p.key] = p.val
            of cmdArgument:
                if filename.len == 0:
                    filename = p.key
                else:
                    raiseAssert("Only one source file should be specified.")

    # Check input
    var showHelp = false
    if filename.len == 0: showHelp = true
    if filename.len > 0 and not fileExists(filename): raiseAssert("File not found: " & filename)

    # Show help if parameters are invalid
    if showHelp:
        echo "Usage: nimcrate myfile.nim"
        return

    # Fetch crate information from the source file
    if not options.contains("outputConfig"): stdout.styledWriteLine(fgBlue, "> ", fgDefault, "Fetching crate information...")
    let result = run("nim", "compile", "--define:NimCrateInformationExport", absolutePath(filename))
    var targets: seq[string]
    var config: Table[string, string]
    var currentTarget = ""
    var currentKey = ""
    var exitedProperly = false
    for line in result.output.splitLines():
        
        # Check line
        if line.startsWith("===NimCrateConfigTarget:"):

            # Store and ensure it's in our target list
            let item = line.substr(24).strip()
            currentTarget = item
            if item.len > 0 and not targets.contains(item):
                targets.add(item)

        elif line.startsWith("===NimCrateConfigKey:"):

            # Store it
            let item = line.substr(21).strip()
            currentKey = item

        elif line.startsWith("===NimCrateConfigValue:"):

            # Store it
            let item = line.substr(23).strip()
            let key = (if currentTarget.len == 0: "" else: currentTarget & "+") & currentKey
            config[key] = item

        elif line.contains("===NimCrateConfigComplete==="):

            # Config complete
            exitedProperly = true
            break


    # Stop if config was not generated properly
    if not exitedProperly:
        echo result.output
        echo ""
        stdout.styledWriteLine(fgRed, "x ", fgDefault, "Unable to fetch crate information.")
        echo ""
        quit(1)

    
    # Add default config options
    config["nimcrateVersion"] = "1"


    # If no version number specified, try get it from the .nimble package
    if config.getOrDefault("version", "") == "":
        config["version"] = getNimbleVersion()



    # If they just want the config output, do that and exit
    if options.contains("outputConfig"):
        for key, value in config.pairs: echo key & "=" & value
        quit(0)


    # Create a temporary directory for building the app, and delete it on exit
    let tempFolder = createTempDir("nimcrate", "build")
    addExitProc(proc() =
        removeDir(tempFolder)
    )

    
    # Add extra config options
    config["sourcefile"] = absolutePath(filename)
    config["temp"] = tempFolder


    # If no targets specified, add all of the known ones
    if targets.len == 0:
        targets = @["windows", "mac", "linux", "web"]


    # Build all platforms
    for target in targets:
        buildTarget(target, config)


# Entry point with error handling
proc run*() =

    # Run and catch errors
    try:
        run2()
    except Exception as ex:
        echo("Error: " & ex.msg)