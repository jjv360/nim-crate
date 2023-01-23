##
## Defines utility functions usable by apps
import std/macros
import std/tables
import std/strutils

## Crate info string, available after the crate: command has run
const NimCrateTargetID* {.strdefine.} = ""
const NimCrateVersion* {.strdefine.} = ""
var NimCrateInfo*: Table[string, string]


proc processCrateCommands(target: string, statements: NimNode) =

    for idx, statement in statements:

        # Check type
        if statement.kind == nnkAsgn and statement[0].kind == nnkIdent:

            # Define property, replace code
            let key = $statement[0]
            let value = statement[1]
            statements[idx] = quote do:
                crateDefine(`target`, `key`, `value`)

        elif statement.kind == nnkCommand and $statement[0] == "target":

            # Output if needed
            let targetID = $statement[1]
            when defined(NimCrateInformationExport):
                echo "===NimCrateConfigTarget: " & targetID

            # Check if target has any extra config options
            if statement.len >= 3:

                # Defining a target
                processCrateCommands(targetID, statement[2])

                # Replace with the code block directly
                statements[idx] = statement[2]

            else:

                # No config options, just replace it with code that does nothing
                statements[idx] = quote do: discard


## Define details about the Crate being built.
macro crate*(code: untyped) =

    # Go through tree
    processCrateCommands("", code)

    # Add wrapper code
    let finalCode = quote do:

        # App code
        `code`

        # Suffix
        crateDefineEnd()

    # Done
    return finalCode


## Define a crate property
template crateDefine*(target: string, key: string, value: string) =

    # Output if needed
    when defined(NimCrateInformationExport):
        static:
            echo "===NimCrateConfigTarget:" & target
            echo "===NimCrateConfigKey:" & key
            echo "===NimCrateConfigValue:" & value.replace("\n", "\\n")

    # Get platform specific key
    let platformKey = if target.len == 0: key else: target & "+" & key

    # Save it
    NimCrateInfo[platformKey] = value

## Define a crate property
template crateDefine*(target: string, name: string, value: bool) = crateDefine(target, name, if value: "1" else: "")
template crateDefine*(target: string, name: string, value: int) = crateDefine(target, name, $value)
template crateDefine*(target: string, name: string, value: float) = crateDefine(target, name, $value)


## End of the crate definition
template crateDefineEnd*() =

    # Stop compiling if we're only wanting the crate output
    when defined(NimCrateInformationExport):
        static:
            echo("===NimCrateConfigComplete===")
            quit(0)


## Utility function to get a field from the Crate info
proc crateField*(key: string): string =

    # Special cases
    if key == "version": return NimCrateVersion     # <-- The version can be dynamically generated

    # Return target-specific field, or the generic one if not found
    return NimCrateInfo.getOrDefault(
        NimCrateTargetID & "+" & key,
        NimCrateInfo.getOrDefault(key, "")
    )