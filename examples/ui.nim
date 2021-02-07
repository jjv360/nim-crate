##
## Name: UI
## Version: 0.1.0
##
## This app displays a UI button. To build: `nimble install nimx` and `nimpack examples/ui.nim`
## 
## Note, since the Windows version of nimx uses SDL, you need to copy the SDL2.dll into the dist folder
## next to the EXE in order to run it.
##

import nimx/window
import nimx/text_field

proc startApp() =
    # First create a window. Window is the root of view hierarchy.
    var wnd = newWindow(newRect(40, 40, 800, 600))

    # Create a static text field and add it to view hierarchy
    let label = newLabel(newRect(20, 20, 150, 20))
    label.text = "Hello, world!"
    wnd.addSubview(label)

# Run the app
runApplication:
    startApp()