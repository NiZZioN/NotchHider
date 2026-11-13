// Usage: listwindows <pid>. Prints "id layer onscreen WxH title" for every window of that process.
import CoreGraphics
let pid = Int(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as! [[String: Any]]
for wi in list where (wi[kCGWindowOwnerPID as String] as? Int) == pid {
    let b = wi[kCGWindowBounds as String] as! [String: Any]
    print(wi[kCGWindowNumber as String]!, "layer", wi[kCGWindowLayer as String]!, "onscreen", wi[kCGWindowIsOnscreen as String] as? Bool ?? false,
          "\(b["Width"]!)x\(b["Height"]!)", wi[kCGWindowName as String] as? String ?? "")
}
