##
## Build for the Windows platform. Generates an EXE file.

import std/tables
import std/terminal
import std/os
import std/strutils
import std/strformat
import classes
import ./platform_base


##
## Build for Windows
class PlatformWindows of Platform:

    ## Platform info
    method id(): string = "windows"
    method name(): string = "Windows"

    ## Return true if we can run on this platform
    method canRunApp(): bool = 
        
        # Only on Windows
        # TODO: Use Wine or CrossOver?
        when defined(windows): 
            return true 
        else: 
            return false


    ## Run the built app on this platform if possible
    method runApp(filePath: string, config: Table[string, string]) =

        # Run it
        runAndPipeOutput filePath


    ## Build
    method build(targetID: string, config: Table[string, string]): BuildOutput =

        # Get binary names
        when defined(windows):
            const mingw = false
            const windres = "windres"
        else:
            const mingw = true
            const windres = "x86_64-w64-mingw32-windres"

        # Create staging directory
        let stagingDir = config["temp"] / "windows"
        if not dirExists(stagingDir):
            createDir(stagingDir)

        # Check if MinGW is installed
        let mingwExe = findExe("x86_64-w64-mingw32-gcc")
        if mingwExe.len == 0:
            stdout.styledWriteLine(fgYellow, "  ! ", fgDefault, "Skipping target '", targetID, "' due to missing MinGW installation. On Mac you can install it with 'brew install mingw'.")
            return

        # Create app manifest
        let manifestPath = stagingDir / "app.manifest"
        writeFile(manifestPath, """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0" xmlns:asmv3="urn:schemas-microsoft-com:asm.v3">
                <!-- DPI awareness setting (per monitor v2) ... https://docs.microsoft.com/en-us/windows/win32/hidpi/high-dpi-desktop-application-development-on-windows -->
                <asmv3:application>
                    <asmv3:windowsSettings>
                        <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true</dpiAware>
                        <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
                    </asmv3:windowsSettings>
                </asmv3:application>
                <!-- WinXP+ control styles -->
                <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2">
                    <security>
                        <requestedPrivileges>
                            <requestedExecutionLevel level="asInvoker" uiAccess="false"/>
                        </requestedPrivileges>
                    </security>
                </trustInfo>
                <dependency>
                    <dependentAssembly>
                        <assemblyIdentity type="Win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="*" publicKeyToken="6595b64144ccf1df" language="*"/>
                    </dependentAssembly>
                </dependency>
            </assembly>
        """.strip())

        # Create temporary resource file
        let resourcePath = stagingDir / "app.rc"
        writeFile(resourcePath, fmt"""
            #include <windows.h>
            CREATEPROCESS_MANIFEST_RESOURCE_ID RT_MANIFEST "{manifestPath.replace("\\", "\\\\")}"
        """.strip())

        # Compile the resource file
        let resourceCompiledPath = stagingDir / "app.res"
        run windres, 
            resourcePath,               # Input file
            "-O", "coff",               # Output COFF format - thanks https://stackoverflow.com/a/67040061/1008736
            "-o", resourceCompiledPath  # Output file

        # Compile app binary
        let outputFilePath = stagingDir / "build.exe"
        run "nim", "compile",

            # Crate flags
            "--define:NimCrate",
            "--define:NimCrateWindows",
            "--define:NimCrateWindows64",
            "--define:NimCrateTargetID=" & targetID,
            "--define:NimCrateVersion=" & config["version"],
            "--out:" & outputFilePath,

            # Architecture and platform flags
            "--cpu:amd64",
            "--os:windows",
            "--app:" & config.getOrDefault("mode", "gui"),
            "--threads:on",
            "--define:release",

            # Windows flags
            "--passL:" & resourceCompiledPath,              # <-- Include our compiled resource file

            # MinGW flags
            if mingw: "--define:mingw" else: "-d:1",
            if mingw: "--gcc.exe:x86_64-w64-mingw32-gcc" else: "-d:1",
            if mingw: "--gcc.linkerexe:x86_64-w64-mingw32-gcc" else: "-d:1",
            
            # Source file path
            config["sourcefile"]

        # Done
        return BuildOutput(filePath: outputFilePath, fileExtension: "exe")