##
## Functions for interacting with CoreFoundation on Mac

# Link required libraries
{.passl:"-framework CoreFoundation".}

# Generic types
type CFTypeRef* = pointer
type CFTimeInterval* = float64
type CFOptionFlags* = uint64
type CFAllocatorRef* = CFTypeRef
type CFIndex = int64

# Generic defines
let kCFNotFound* {.importc, header: "<CoreFoundation/CoreFoundation.h>".} : CFIndex

# Memory management
# Note: On MacOS any function that has "Create" or "Copy" in the function name means you own the returned object, and you must release it when done.
# Anything with "Get" in the function name you don't own, and you must not release it. See: https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFMemoryMgmt/Concepts/Ownership.html#//apple_ref/doc/uid/20001148-103029
let kCFAllocatorDefault* {.importc, header: "<CoreFoundation/CoreFoundation.h>".} : CFAllocatorRef 
proc CFRelease*(cf: CFTypeRef) {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

# String stuff
type CFStringRef* = CFTypeRef
type CFStringEncoding* = uint32
let kCFStringEncodingUTF8* {.importc, header: "<CoreFoundation/CoreFoundation.h>".} : CFStringEncoding
proc CFStringCreateWithCString*(allocator: CFAllocatorRef = kCFAllocatorDefault, cStr: cstring, encoding: CFStringEncoding = kCFStringEncodingUTF8): CFStringRef {.importc, header: "<CoreFoundation/CoreFoundation.h>".}
proc CFStringGetMaximumSizeForEncoding*(length: CFIndex, encoding: CFStringEncoding = kCFStringEncodingUTF8): CFIndex {.importc, header: "<CoreFoundation/CoreFoundation.h>".}
proc CFStringGetLength*(theString: CFStringRef): CFIndex {.importc, header: "<CoreFoundation/CoreFoundation.h>".}
proc CFStringGetCStringPtr*(theString: CFStringRef, encoding: CFStringEncoding = kCFStringEncodingUTF8): cstring {.importc, header: "<CoreFoundation/CoreFoundation.h>".}
proc CFStringGetCString*(theString: CFStringRef, buffer: pointer, bufferSize: CFIndex, encoding: CFStringEncoding = kCFStringEncodingUTF8): bool {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

# Utility stuff
proc CFCopyDescription*(cf: CFTypeRef): CFStringRef {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

# URL stuff
type CFURLRef* = CFTypeRef
proc CFURLCreateWithString*(allocator: CFAllocatorRef = kCFAllocatorDefault, urlString: CFStringRef, baseURL: CFURLRef = nil): CFURLRef {.importc, header: "<CoreFoundation/CoreFoundation.h>".}

# Dialog stuff
let kCFUserNotificationPlainAlertLevel* {.importc, header: "<CoreFoundation/CoreFoundation.h>".} : CFOptionFlags
proc CFUserNotificationDisplayAlert*(timeout: CFTimeInterval = 0, flags: CFOptionFlags = kCFUserNotificationPlainAlertLevel, iconURL: CFURLRef = nil, soundURL: CFURLRef = nil, localizationURL: CFURLRef = nil, alertHeader: CFStringRef = nil, alertMessage: CFStringRef = nil, defaultButtonTitle: CFStringRef = nil, alternateButtonTitle: CFStringRef = nil, otherButtonTitle: CFStringRef = nil, responseFlags: ptr CFOptionFlags = nil): int32 {.importc, header: "<CoreFoundation/CoreFoundation.h>".}




#############################





# Convert a CFStringRef to a Nim string
converter cfStringToString*(cfString: CFStringRef): string =

    # Attempt to get a direct UTF8 CString ... this only works if the CFString was created with UTF8 data, but if it does work, it's hella quick
    let str = CFStringGetCStringPtr(cfString)
    if str != nil:
        return $str

    # Create a buffer of the appropriate size
    let stringLen = CFStringGetLength(cfString)
    let bufferSize = CFStringGetMaximumSizeForEncoding(stringLen) + 1
    if bufferSize == kCFNotFound: return ""
    var buffer = alloc0(bufferSize)

    # Copy string to the buffer
    let success = CFStringGetCString(cfString, buffer, bufferSize)
    if not success:
        dealloc(buffer)
        return ""

    # Convert to normal string
    let normalStr = $cast[cstring](buffer)

    # Release memory
    dealloc(buffer)

    # Done
    return normalStr


# Convert a Nim string to a CFStringRef
# TODO: No idea how memory management is handled for the resulting pointer ... we need to call CFRelease on it somehow... Using destructors maybe?
converter stringToCfString*(str: string): CFStringRef =
    return CFStringCreateWithCString(cStr = str)


# Get description for any CoreFoundation type as a string
proc `$`*(item: CFTypeRef): string {.used.} =
    let cfString = CFCopyDescription(item)
    let str: string = cfString
    CFRelease(cfString)
    return str

