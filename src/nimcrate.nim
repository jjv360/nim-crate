# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

# When running as a binary, run the CLI module, otherwise export packages
when isMainModule:
    import nimcratepkg/cli
    cli.run()
else:
    import nimcratepkg/lib
    export lib