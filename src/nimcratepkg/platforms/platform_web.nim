import std/tables
import std/os
import std/strutils
import classes
import ./platform_base

##
## Build for Web
class PlatformWeb of Platform:

    ## Platform info
    method id(): string = "web"
    method name(): string = "Web"

    ## Build
    method build(targetID: string, config: Table[string, string]): BuildOutput =

        # Create staging directory
        let stagingDir = config["temp"] / "web"
        if not dirExists(stagingDir):
            createDir(stagingDir)

        # Compile to JavaScript
        let jsPath = stagingDir / "code.js"
        run "nim", "js",

            # Crate flags
            "--define:NimCrate",
            "--define:NimCrateVersion=" & config["version"],
            "--define:NimCrateTargetID=" & targetID,
            "--define:NimCrateWeb",
            "--out:" & jsPath,

            # Architecture and platform flags
            "--define:release",
            
            # Source file path
            config["sourcefile"]

        # Read entire JS code
        let jsCode = readFile(jsPath)

        # Create wrapper html
        let appTitle = config.getOrDefault("name", "App")
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
        return BuildOutput(filePath: outputFilePath, fileExtension: "html")
