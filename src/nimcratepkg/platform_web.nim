import std/tables
import std/terminal
import std/osproc
import std/os
import std/strutils
import std/strformat

# Execute process and return the exit code
proc run(args: varargs[string]) =

    # Run command
    let cmd = args.quoteShellCommand()
    # echo "Run: " & cmd
    let result = execCmdEx(cmd, { poStdErrToStdOut })

    # Check if failed
    if result.exitCode != 0:
        echo result.output
        echo ""
        stdout.styledWriteLine(fgRed, "x ", fgDefault, "Failed to build.")
        quit(2)


proc buildWeb*(targetID: string, config: Table[string, string]) =

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
    let outputFilePath = absolutePath("dist" / targetID.replace(":", "-") & ".html")
    writeFile(outputFilePath, """
        <!DOCTYPE html>
        <html>
        <head>
            <title>`appTitle`</title>
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
            <script>`jsCode`</script>
            
        </body>
        </html>
    """.fmt('`', '`').strip())
