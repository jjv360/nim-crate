import docopt
import os
import osproc
import strutils
import elvis

# Help document
let helpDoc = """
TizenNim - build Tizen apps in Nim.

Usage:
    nimpack <file>

Options:
    -h --help               Show this screen.

"""

# Adds common executable extensions
proc resolveExeExtension(exe: string): string =
    if fileExists(exe): return exe
    elif fileExists(exe & ".exe"): return exe & ".exe"
    elif fileExists(exe & ".bat"): return exe & ".bat"
    elif fileExists(exe & ".cmd"): return exe & ".cmd"
    elif fileExists(exe & ".sh"): return exe & ".sh"
    raiseAssert("File not found: " & exe)

# Execute process and return the exit code
proc runCmd(exe: string, options: varargs[string]): int =

    # Create the process
    let p = startProcess(command = resolveExeExtension(exe), workingDir = getCurrentDir(), args = options, env = nil, options = { poParentStreams })
    return p.waitForExit()


# Build for Windows
proc buildWindows(appInfo: Table[string, string]): string =

    # Build for Windows
    echo ""
    echo "======== Building for Windows ========"
    let outputFile = absolutePath(appInfo["sourceFile"] / ".." / "dist" / appInfo["name"] & " for Windows.exe")
    var code = runCmd(
        appInfo["nimExe"],
        "compile",
        "--os:windows",
        appInfo["console"] ? "--app:console" ! "--app:gui",
        "--out:" & outputFile,
        appInfo["sourceFile"]
    )
    doAssert(code == 0, "Failed to compile the app.")

    # Done
    return outputFile


# Build for Web
proc buildWeb(appInfo: Table[string, string]): string =

    # Build for JavaScript
    echo ""
    echo "======== Building for Web ========"
    let outputFile = absolutePath(appInfo["sourceFile"] / ".." / "dist" / "app.js")
    var code = runCmd(
        appInfo["nimExe"],
        "js",
        "--out:" & outputFile,
        appInfo["sourceFile"]
    )
    doAssert(code == 0, "Failed to compile the app.")

    # Load wrapper file
    const wrapperFile = staticRead("wrapper.html")

    # Replace vars
    var finalWrapper = wrapperFile
    finalWrapper = finalWrapper.replace("REPLACE_APP_TITLE", appInfo["name"])
    finalWrapper = finalWrapper.replace("REPLACE_APP_CODE", readFile(outputFile))

    # Delete output file
    removeFile(outputFile)

    # Save wrapped app
    let htmlOutputFile = absolutePath(appInfo["sourceFile"] / ".." / "dist" / appInfo["name"] & " for Web.html")
    writeFile(htmlOutputFile, finalWrapper)

    # Done
    return htmlOutputFile


# Entry point
proc run2() =

    # Echo header
    echo ("")
    echo (" +----------------------+")
    echo (" |       Nim Pack       |")
    echo (" +----------------------+")
    echo ("")

    # Parse opts
    let args = docopt(helpDoc)

    # Get file name
    let nimFile = absolutePath($args["<file>"])
    if not fileExists(nimFile): raiseAssert("File not found: " & nimFile)

    # Get app name from file
    var appInfo = initTable[string, string]()
    appInfo["name"] = splitFile(nimFile).name
    appInfo["description"] = "Packaged with Nimpack."
    appInfo["version"] = "0.1.0"
    appInfo["sourceFile"] = nimFile
    appInfo["nimExe"] = absolutePath(os.findExe("nim"))

    # Read app info from top header of the entry file
    for line in nimFile.lines:

        # Ignore blank lines
        if line.isEmptyOrWhitespace():
            continue

        # Stop if not a header comment
        if line.startsWith("#!"): continue
        if not line.startsWith("##"): break

        # Find index of :
        let idx = line.find(":")
        if idx == -1:
            continue

        # Add info
        let key = line.substr(2, idx-1).strip().toLower()
        let value = line.substr(idx+1).strip()
        appInfo[key] = value

    # Build for each platform
    var outputs = newSeq[string]()
    outputs &= buildWindows(appInfo)
    outputs &= buildWeb(appInfo)

    # Done
    echo ""
    echo "Outputs:"
    for file in outputs: echo " - " & file
    echo ""




# Entry point with error handling
proc run*() =

    # Run and catch errors
    try:
        run2()
    except Exception as ex:
        echo("Error: " & ex.msg)