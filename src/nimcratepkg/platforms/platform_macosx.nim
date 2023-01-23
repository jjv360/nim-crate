import std/tables
import std/terminal
import std/os
import std/json
import plists
import classes
import ./platform_base


##
## Build a Mac OS X application
## See: https://forum.nim-lang.org/t/8129
## See: https://stackoverflow.com/a/3251285/1008736
class PlatformMac of Platform:

    ## Platform info
    method id(): string = "macosx"
    method name(): string = "Mac OS X"

    ## Build
    method build(targetID: string, config: Table[string, string]): BuildOutput =

        # Only supported on MacOS
        when not defined(macosx):
            raiseAssert("Only supported on Mac OS X")

        # Create staging directory
        let stagingDir = config["temp"] / "macosx"
        createDir(stagingDir)
        
        # Compile for x64
        stdout.styledWriteLine(fgBlue, "  > ", fgDefault, "Building app for Intel")
        run "nim", "compile",

            # Crate flags
            "--define:NimCrate",
            "--define:NimCrateMacOSX",
            "--define:NimCrateTargetID=" & targetID,
            "--define:NimCrateVersion=" & config["version"],
            "--out:" & stagingDir / "app-amd64",

            # Architecture and platform flags
            "--os:macosx",
            "--cpu:amd64",
            "--app:gui",
            "--threads:on",
            "--define:release",

            # Compiler flags
            "--passC:-target x86_64-apple-macos10.12",
            "--passL:-target x86_64-apple-macos10.12",
            "--passL:-headerpad_max_install_names",
            
            # Source file path
            config["sourcefile"]
        
        # Compile for arm64 (M1 Macs)
        stdout.styledWriteLine(fgBlue, "  > ", fgDefault, "Building app for M1")
        run "nim", "compile",

            # Crate flags
            "--define:NimCrate",
            "--define:NimCrateMacOSX",
            "--define:NimCrateTargetID=" & targetID,
            "--define:NimCrateVersion=" & config["version"],
            "--out:" & stagingDir / "app-arm64",

            # Architecture and platform flags
            "--os:macosx",
            "--cpu:arm64",
            "--app:gui",
            "--threads:on",
            "--define:release",

            # Compiler flags
            "--passC:-target arm64-apple-macos11",
            "--passL:-target arm64-apple-macos11",
            "--passL:-headerpad_max_install_names",
            
            # Source file path
            config["sourcefile"]

        # Link binaries into a single universal binary
        run "lipo", "-create", 
            "-output", stagingDir / "app-universal",    # <-- Output binary
            stagingDir / "app-arm64",                   # <-- Input binary
            stagingDir / "app-amd64"                    # <-- Input binary

        # Create .app bundle
        let bundlePath = stagingDir / "NimApp.app"
        createDir(bundlePath)
        
        # Add the binary to it
        createDir(bundlePath / "Contents" / "MacOS")
        copyFile(stagingDir / "app-universal", bundlePath / "Contents" / "MacOS" / "nimApp")

        # Create the info plist
        let plistPath = bundlePath / "Contents" / "Info.plist"
        writePlist( %* {

            # Describe this bundle as an app
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundlePackageType": "APPL",
            "IFMajorVersion": 0,
            "IFMinorVersion": 1,

            # App details
            "CFBundleIdentifier": config["id"],
            "CFBundleName": config["name"],
            "CFBundleShortVersionString": config["version"],
            "CFBundleGetInfoString": config["name"],

            # Execution details
            "CFBundleExecutable": "nimApp",                     # <-- The name of the binary in the MacOS folder

        }, plistPath)

        # Done
        return BuildOutput(filePath: bundlePath, fileExtension: "app")