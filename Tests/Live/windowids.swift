// Usage: windowids <pid>. Prints "id x y w h" for each strip window of that process.
import CoreGraphics
let pid = Int(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as! [[String: Any]]
for wi in list where (wi[kCGWindowOwnerPID as String] as? Int) == pid {
    guard (wi[kCGWindowLayer as String] as? Int) == 23 else { continue } // strip: one below the menu bar (24)
    let b = wi[kCGWindowBounds as String] as! [String: Any]
    print(wi[kCGWindowNumber as String]!, b["X"]!, b["Y"]!, b["Width"]!, b["Height"]!)
}
