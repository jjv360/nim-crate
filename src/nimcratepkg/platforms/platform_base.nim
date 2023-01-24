import classes
import std/tables
import std/os
import std/osproc


##
## Build output information
class BuildOutput:

    ## Location of the output file
    var filePath = ""

    ## Application extension for this platform
    var fileExtension = ""


##
## Base class for a platform
class Platform:

    ## Platform ID
    method id(): string = ""

    ## Platform name
    method name(): string = ""

    ## Build for this platform
    method build(targetID: string, config: Table[string, string]): BuildOutput =
        raiseAssert("Build for this platform is not supported.")

    ## Return true if we can run on this platform
    method canRunApp(): bool = false

    ## Run the built app on this platform if possible
    method runApp(filePath: string, config: Table[string, string]) = discard


## Utility: Run a command and return the text output, and fail if the exit code is not zero
proc run*(args: varargs[string]) =

    # Run command
    let cmd = args.quoteShellCommand()
    let result = execCmdEx(cmd, { poStdErrToStdOut })

    # Check if failed
    if result.exitCode != 0:
        echo "Command: " & cmd
        echo result.output
        raiseAssert("Command failed.")


## Utility: Run a command and pipe output to the console
proc runAndPipeOutput*(args: varargs[string]) =
    let cmd = args.quoteShellCommand()
    discard execCmd(cmd)




# Utility: Execute process and return the exit code
proc runWithExitCode*(args: varargs[string]): tuple[output: string, exitCode: int] =
    let cmd = args.quoteShellCommand()
    return execCmdEx(cmd, { poStdErrToStdOut })