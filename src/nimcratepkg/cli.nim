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
# import ./platforms/platform_ios

# Create list of active platforms
# Note: The order is important, since it will be used to determine which binary to run if --run is specified
let platforms = @[
    PlatformMac.init(),
    PlatformWindows.init(),
    # PlatformiOS.init(),
    PlatformWeb.init(),
]

## Help text
const helpText = """
NimCrate - Package your Nim app for multiple platforms. 
Usage:

    nimcrate <nimfile> [options]

Options:

    <nimfile>           Path to your main Nim source file.
    --debug             If specified, builds your source in debug mode.
    --outDir:x          Specify where to save built apps. Defaults to "dist".
    --outputConfig      Skip build and only output the configuration info for this Crate.
    --run               Runs the app after building. Can be used with --target where possible.
    --target:?          Specify which target to build. By default builds all targets.

Targets:

    macosx              Builds a Mac OS X application bundle. (requires running on Mac)
    web                 Builds an HTML single-page application.
    windows             Builds a Windows 64-bit EXE.

    You can also specify target variants by appending :name to a target. For example you could have
    windows:dev and windows:prod variants, and then customize your app based on the target.

Nim defines:

    NimCrate            Always defined when building via this tool
    NimCrateID          The ID of the crate being built
    NimCrateTargetID    The name of the target being built
    NimCrateVersion     The version string of your Crate

"""


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

    # Show help if parameters are invalid
    if options.hasKey("help"):
        echo helpText
        return

    # Check input
    let outDir = absolutePath(options.getOrDefault("outDir", "dist"))
    if filename.len == 0: raiseAssert("No input file specified.")
    if filename.len > 0 and not fileExists(filename): raiseAssert("File not found: " & filename)

    # Fetch crate information from the source file
    if not options.contains("outputConfig"): stdout.styledWriteLine(fgBlue, "> ", resetStyle, "Fetching crate information...")
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
        stdout.styledWriteLine(fgRed, "x ", resetStyle, "Unable to fetch crate information.")
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

    # If no targets specified and --run is specified, build for the current platform
    if targets.len == 0 and options.hasKey("run"):
        when defined(macosx):
            targets.add("macosx")
        elif defined(windows):
            targets.add("windows")
        else:
            targets.add("web")      # <-- Fallback to Web if unknown platform ... we can try run it with Chrome

    # If no targets specified, add all of the known platforms as targets
    if targets.len == 0:
        for p in platforms:
            targets.add(p.id)

    # If they specified a specific target on the command line, build that one only
    if options.getOrDefault("target", "") != "":
        targets = @[ options["target"] ]

    # Build all platforms
    var didRun = false
    for targetID in targets:

        # Start building this target
        stdout.styledWriteLine(fgBlue, "> ", resetStyle, "Building target: ", targetID)

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

            # If --run is specified, only build if we can run on this platform
            if options.hasKey("run") and not platform.canRunApp():
                continue
            
            # Build and get output
            let buildInfo = platform.build(targetID, config)

            # Get output file name
            var outName = (config["name"] & " (" & targetID & ")").replace(re"[:;'*?]", "-")
            if buildInfo.fileExtension != "": outName = outName & "." & buildInfo.fileExtension
            let outPath = config["outDir"] / outName

            # Remove existing files
            createDir(config["outDir"])
            if dirExists(outPath): removeDir(outPath)
            if fileExists(outPath): removeFile(outPath)

            # Move to output directory
            if dirExists(buildInfo.filePath):
                moveDir(buildInfo.filePath, outPath)
            else:
                moveFile(buildInfo.filePath, outPath)

            # If --run is specified, run the app
            if options.hasKey("run"):
                stdout.styledWriteLine(fgBlue, "> ", resetStyle, "Launching app...")
                didRun = true
                platform.runApp(outPath, config)
                break

        except Exception as err:

            # Build failed
            stdout.styledWriteLine(fgRed, "  x ", resetStyle, "Build failed: ", err.msg)

    # Show warning if no platform to run was built
    if options.hasKey("run") and not didRun:
        stdout.styledWriteLine(fgYellow, "  ! ", resetStyle, "Unable to run app on this platform")
        quit(2)


# Entry point with error handling
proc run*() =

    # Run and catch errors
    try:
        run2()
    except Exception as ex:
        stdout.styledWriteLine(fgRed, "Error: ", resetStyle, ex.msg)