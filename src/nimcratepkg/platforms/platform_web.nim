import std/tables
import std/os
import std/strutils
import classes
import ./platform_base

# List of possible locations for the Chrome EXE
let chromeBinaryLocations = @[

    # Common paths on Windows
    "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe", 
    "C:/Program Files (x86)/Google/Application/chrome.exe", 
    "~/AppDataLocal/Google/Chrome/chrome.exe",

    # Common paths on *nix
    "/usr/bin/google-chrome", 
    "/usr/local/sbin/google-chrome", 
    "/usr/local/bin/google-chrome", 
    "/usr/sbin/google-chrome", 
    "/usr/bin/chrome", 
    "/sbin/google-chrome", 
    "/bin/google-chrome",

    # Common paths on MacOS
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "~/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",

    # Check for it on the PATH
    findExe("chrome"),

]

##
## Build for Web
class PlatformWeb of Platform:

    ## Platform info
    method id(): string = "web"
    method name(): string = "Web"

    ## Return true if we can run on this platform
    method canRunApp(): bool = 
        
        # Find Chrome EXE
        return findExeInList(chromeBinaryLocations) != ""


    ## Run the built app on this platform if possible
    method runApp(output: BuildOutput) =

        # Run it with Chrome
        runAndPipeOutput findExeInList(chromeBinaryLocations),
            "--app=file://" & output.filePath,
            "--allow-file-access",
            "--allow-file-access-from-files",
            "--window-size=1024,768",
            "--user-data-dir=" & (output.build.config["temp"] / "chromedata"),
            # "--chrome-frame",
            # "--single-process",
            "--disable-renderer-backgrounding",
            "--disable-background-networking",
            "--disable-extensions",     # <-- Extensions may prevent the process from exiting when the window is closed
            "--disable-component-extensions-with-background-pages",
            "--disable-features=Translate",
            "--disable-backgrounding-occluded-windows",
            "--enable-logging=stderr",
            "--disable-breakpad",
            "--no-first-run"


    ## Build
    method build(build: BuildConfig): BuildOutput =

        # Create staging directory
        let stagingDir = build.config["temp"] / "web"
        if not dirExists(stagingDir):
            createDir(stagingDir)

        # Compile to JavaScript
        let jsPath = stagingDir / "code.js"
        run "nim", "js",

            # Crate flags
            "--define:NimCrate",
            "--define:NimCrateVersion=" & build.config["version"],
            "--define:NimCrateTargetID=" & build.targetID,
            "--define:NimCrateWeb",
            "--define:NimCrateID=" & build.config["id"],
            "--out:" & jsPath,

            # Architecture and platform flags
            "--mm:orc",
            if build.config["debug"] == "": "--define:release" else: "--define:debug",
            
            # Source file path
            build.config["sourcefile"]

        # Read entire JS code
        let jsCode = readFile(jsPath)

        # Create wrapper html
        let appTitle = build.config.getOrDefault("name", "App")
        let outputFilePath = stagingDir / "index.html"
        writeFile(outputFilePath, """
            <!DOCTYPE html>
            <html>
            <head>
                <title>""" & appTitle & """</title>
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            </head>
            <body>
                <!-- Web app default styling -->
                <style>
                    html, body {
                        margin: 0px;
                        padding: 0px;
                    }
                </style>

                <!-- App code -->
                <script>""" & jsCode & """</script>
                
            </body>
            </html>
        """.strip())

        # Done
        return BuildOutput(build: build, filePath: outputFilePath, fileExtension: "html")
