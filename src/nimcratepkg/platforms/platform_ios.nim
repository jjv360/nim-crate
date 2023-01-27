import std/tables
import std/terminal
import std/os
import std/json
import plists
import classes
import ./platform_base


##
## Build an iOS application
## See: https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle
## See: https://thisisyuu.github.io/2020/MISC-Building-universal-binaries-from-C-library-for-an-iOS-project/
## See: https://stackoverflow.com/a/23543343/1008736
## See: https://stackoverflow.com/questions/41007556 (sysroot)
class PlatformiOS of Platform:

    ## Platform info
    method id(): string = "ios"
    method name(): string = "iOS"

    ## Build
    method build(build: BuildConfig): BuildOutput =

        # Only supported on MacOS
        when not defined(macosx):
            raiseAssert("Only supported on Mac OS X")

        # Create staging directory
        let stagingDir = build.config["temp"] / "ios"
        createDir(stagingDir)
        
        # Compile for x64
        stdout.styledWriteLine(fgBlue, "  > ", resetStyle, "Building app for x86_64 (Simulator)")
        run "nim", "compile",

            # Crate flags
            "--define:NimCrate",
            "--define:NimCrateiOS",
            "--define:NimCrateTargetID=" & build.targetID,
            "--define:NimCrateVersion=" & build.config["version"],
            "--out:" & stagingDir / "app-amd64",

            # Architecture and platform flags
            "--os:ios",
            "--cpu:amd64",
            "--app:gui",
            "--threads:on",
            "--define:ios",
            "--define:release",

            # Compiler flags
            "--passC:-target x86_64-apple-ios-simulator",
            "--passL:-target x86_64-apple-ios-simulator",
            "--passC:-mios-simulator-version-min=13.0",
            "--passL:-mios-simulator-version-min=13.0",
            "--passC:-fembed-bitcode",
            "--passL:-fembed-bitcode",
            # "--passL:-headerpad_max_install_names",
            
            # Source file path
            build.config["sourcefile"]
        
        # Compile for arm64 (M1 Macs)
        stdout.styledWriteLine(fgBlue, "  > ", resetStyle, "Building app for ARM64")
        run "nim", "compile",

            # Crate flags
            "--define:NimCrate",
            "--define:NimCrateiOS",
            "--define:NimCrateTargetID=" & build.targetID,
            "--define:NimCrateVersion=" & build.config["version"],
            "--define:NimCrateID=" & build.config["id"],
            "--out:" & stagingDir / "app-arm64",

            # Architecture and platform flags
            "--os:ios",
            "--cpu:arm64",
            "--app:gui",
            "--define:ios",
            if build.config["debug"] == "": "--define:release" else: "--define:debug",

            # Compiler flags
            "--threads:on",
            "--mm:orc",
            "--passC:-target arm64-apple-ios",
            "--passL:-target arm64-apple-ios",
            "--passC:-fembed-bitcode",
            "--passL:-fembed-bitcode",
            "--passL:-headerpad_max_install_names",
            
            # Source file path
            build.config["sourcefile"]

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
            "CFBundleIdentifier": build.config["id"],
            "CFBundleName": build.config["name"],
            "CFBundleShortVersionString": build.config["version"],
            "CFBundleGetInfoString": build.config["name"],

            # Execution details
            "CFBundleExecutable": "nimApp",                     # <-- The name of the binary in the MacOS folder

        }, plistPath)

        # TODO: Copy dylibs automatically to the MacOS folder and reassign paths in the binary

        # TODO: Sign the app

        # Done
        return BuildOutput(build: build, filePath: bundlePath, fileExtension: "app")