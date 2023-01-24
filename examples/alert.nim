import nimcrate
crate:
    id = "jjv360.nimcrate.alert"
    name = "Alert Example"
    description = "This app shows an alert box and then exits. To build: `nimcrate examples/alert.nim`"


# Check how to show
import std/strformat
let id = crateField("id")
let name = crateField("name")
let version = crateField("version")
let message = fmt"Hello from {name} ({id}) version {version}"
when defined(js):

    # Show alert in the browser
    import std/dom
    window.alert(message)

elif defined(windows):

    # Show alert on Windows
    import winim/lean
    MessageBox(0, message, "Hello World!", MB_OK or MB_ICONINFORMATION)

elif defined(ios):

    # Show alert on Mac OS X
    echo message

elif defined(macosx):

    # Show alert on Mac OS X
    import ./utils/corefoundation
    discard CFUserNotificationDisplayAlert(alertHeader = "Hello World!", alertMessage = message)

else:

    # Just show it in the console
    echo "Hello World!"