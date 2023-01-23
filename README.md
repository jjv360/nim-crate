# Crate - App packager for Nim

![](https://img.shields.io/badge/status-incomplete-lightgray)

This tool packages your Nim GUI application for multiple platforms, handling cross-compilation automatically. 
It takes your Nim binary and app resources and bundles them into "crates". For example, an `.app` for Mac, `.ipa` for iOS, `.apk` for Andorid, etc.

## Usage

1. Install with `nimble install https://github.com/jjv360/crate`
2. Add Crate details to your source (optional)
3. Run `nimcrate myapp.nim` to build your app for each platform
4. Output is saved to the `dist/` folder.

## Specifying Crate information

You can define extra Crate information by adding the `crate:` section to the top of your main Nim file. Example:

```
import nimcrate
crate:
    id = "com.myapp"
    name = "My App"
```

See [the docs](./Documentation.md) for all available fields.