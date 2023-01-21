# Nim Crate - Documentation

This document lists all command line flags and library methods you can use when building a Crate application.


## Command Line

The `nimcrate` command can be used to build and package Crate applications. All flags are optional.

```shell
nimcrate <sourcefile> [flags]
```

Flag                    | Description
------------------------|----------------------
`--outputConfig`        | If specified, will only output the Crate configuration information and not build anything.
`--target:xxx`          | Build the specified target only. By default all targets are built.
`--debug`               | If specified, builds all targets in debug mode. This overrides the `debug` target option.


## Crate configuration

The Crate information should be specified at the top of your main Nim source file. All parameters are optional, but you should at least specify `id` to help identify the app.

```nim
import nimcrate
crate:
    
    # Crate information
    id = "com.myapp"
    name = "My App"

    # Customize targets
    target "mac"
    target "web"
    target "windows"
    target "windows:debug":
        name = "My App (debug)"
```

> **Note:** If you specify custom targets, the default targets will not be applied, so you need to specify all the targets you want to use.

Each **target** will result in an output in the `dist/` folder when built. All configuration options can be overridden for a specific target.

The target name must start with the platform ID, or contain only the platform ID. For example, `"windows"` and `"windows:debug"` will both build for `"windows"`. You can use any target name after the `:`.

Option                  | Description
------------------------|--------------------------
`id`                    | The application ID or bundle ID. This must be unique to your app.
`name`                  | The display name of your app.
`description`           | A short description of your app.
`version`               | Your app's version number. If not specified, will fetch from your `.nimble` file instead. This must be in the format `Major.Minor.Patch`, for example: `0.1.23`.
`debug`                 | If true, will compile in debug mode instead of release.