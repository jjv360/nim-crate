import nimcrate
crate:
    id = "jjv360.nimcrate.alert"
    name = "Alert Example"
    description = "This app shows an alert box and then exits. To build: `nimcrate examples/alert.nim`"
    target "windows"
    target "macosx"
    target "web"
    target "web:dev":
        name = "Alert Example (dev)"


# Check how to show
let message = "Hello from " & crateField("name") & " version " & crateField("version")
when defined(js):

    # Show alert in the browser
    import std/dom
    window.alert(message)

elif defined(windows):

    # Show alert on Windows
    import winim/lean
    MessageBox(0, message, "Hello World!", MB_OK or MB_ICONINFORMATION)

elif defined(macosx):

    # Show alert on Mac OS X
    import ./utils/corefoundation
    discard CFUserNotificationDisplayAlert(alertHeader = "Hello World!", alertMessage = message)

else:

    # Just show it in the console
    echo "Hello World!"