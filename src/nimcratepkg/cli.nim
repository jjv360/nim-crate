import std/os
import std/strutils
import std/parseopt
import std/tables
import std/terminal
import std/tempfiles
import std/exitprocs
import std/json
import std/re
import ./platforms/platform_base
import ./platforms/platform_windows
import ./platforms/platform_web
import ./platforms/platform_macosx

# Create list of active platforms
let platforms = @[
    PlatformMac.init(),
    PlatformWeb.init(),
    PlatformWindows.init(),
]


## Get package version from .nimble file
proc getNimbleVersion(): string =

    # Catch errors
    try:

        # Get it
        let result2 = runWithExitCode("nimble", "dump", "--json")
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
    let outDir = absolutePath(options.getOrDefault("outDir", "dist"))
    var showHelp = false
    if filename.len == 0: showHelp = true
    if filename.len > 0 and not fileExists(filename): raiseAssert("File not found: " & filename)

    # Show help if parameters are invalid
    if showHelp:
        echo "Usage: nimcrate myfile.nim"
        return

    # Fetch crate information from the source file
    if not options.contains("outputConfig"): stdout.styledWriteLine(fgBlue, "> ", fgDefault, "Fetching crate information...")
    let result = runWithExitCode("nim", "r", "--define:NimCrateInformationExport", absolutePath(filename))
    var targets: seq[string]
    var config: Table[string, string]
    var currentTarget = ""
    var currentKey = ""
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


    # Stop if config was not generated properly
    if result.exitCode != 0:
        echo result.output
        echo ""
        stdout.styledWriteLine(fgRed, "x ", fgDefault, "Unable to fetch crate information.")
        echo ""
        quit(1)

    
    # Add default config options
    config["nimcrateVersion"] = "1"
    config["outDir"] = outDir
    config["sourcefile"] = absolutePath(filename)
    config["debug"] = options.getOrDefault("debug")

    # If no ID specified, use the input file name
    if config.getOrDefault("id", "") == "":
        var n = extractFilename(filename)
        if n.endsWith(".nim"): n = n.substr(0, n.len - 5)
        n = n.replace(re"[^0-9A-Za-z\.]", "_").toLower()
        config["id"] = "org.nimcrate." & n

    # If no name specified, use the input file name
    if config.getOrDefault("name", "") == "":
        var n = extractFilename(filename)
        if n.endsWith(".nim"): n = n.substr(0, n.len - 5)
        n = n.replace(re"[^0-9A-Za-z\.\(\) ]", " ").strip()
        config["name"] = n

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
    config["temp"] = tempFolder

    # If no targets specified, add all of the known ones
    if targets.len == 0:
        targets = @["windows", "macosx", "linux", "web"]

    # If they specified a specific target on the command line, build that one only
    if options.getOrDefault("target", "") != "":
        targets = @[ options["target"] ]

    # Build all platforms
    for targetID in targets:

        # Start building this target
        stdout.styledWriteLine(fgBlue, "> ", fgDefault, "Building target: ", targetID)

        # Catch errors
        try:

            # Get platform ID
            var platformID = targetID
            let idx = platformID.find(":")
            if idx >= 0:
                platformID = platformID.substr(0, idx-1)

            # Find platform class
            var platform: Platform = nil
            for p in platforms:
                if p.id == platformID:
                    platform = p
                    break

            # Stop if not found
            if platform == nil:
                raiseAssert("Platform '" & platformID & "' not supported.")
            
            # Build and get output
            let buildInfo = platform.build(targetID, config)

            # Get output file name
            var outName = targetID.replace(re"[^0-9a-zA-Z]", "-")
            if buildInfo.fileExtension != "":
                outName = outName & "." & buildInfo.fileExtension

            # Move to output directory
            createDir(config["outDir"])
            if dirExists(buildInfo.filePath):
                moveDir(buildInfo.filePath, config["outDir"] / outName)
            else:
                moveFile(buildInfo.filePath, config["outDir"] / outName)

        except Exception as err:

            # Build failed
            stdout.styledWriteLine(fgRed, "  x ", fgDefault, "Build failed: ", err.msg)


# Entry point with error handling
proc run*() =

    # Run and catch errors
    try:
        run2()
    except Exception as ex:
        echo("Error: " & ex.msg)