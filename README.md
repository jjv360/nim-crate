# Crate - App packager for Nim

![](https://img.shields.io/badge/status-incomplete-lightgray)

This tool packages your Nim GUI application for multiple platforms, handling cross-compilation automatically.

## Usage

1. Install with `nimble install https://github.com/jjv360/crate`
2. Add Crate details to your source (see below)
3. Run `nimcrate myapp.nim` to build your app
4. Output is saved to the `dist/` folder.

## Specifying Crate information

To convert your Nim code into a Crate which can be built for multiple platforms, you need to specify the crate information in your Nim source code. This can be done by adding the `crate:` section to the top of your main Nim file. Example:

```
import nimcrate
crate:
    id = "com.myapp"
    name = "My App"
```

All Crate fields are optional, but you should specify `id` at least. See [the docs](./Documentation.md) for all available fields.
