# Nimpack - App packager

![](https://img.shields.io/badge/status-incomplete-lightgray)

This tool packages your GUI Nim application as a single portable executable on all platforms.

## Usage

1. Install with `nimble install nimpack`
2. Go to your project directory and run `nimpack myapp.nim`
3. Output is saved to the `dist/` folder.

## Features

Feature                     | Windows | Mac | Linux | Web
----------------------------|---------|-----|-------|-----
Single executable           | ✔️     | ❌  | ❌   | ✔️
Resource files              | ❌     | ❌  | ❌   | ❌

## Specifying app information

```nim
## Name: My app name
## Description: My app's short description
## Version: 0.1.0
##
## App details are read from the first ## comment at the top of your input file.
##

... your code here ...
```