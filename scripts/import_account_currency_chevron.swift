import AppKit
import CryptoKit
import Foundation

// Import the reviewed, downloaded chevron; crop only transparent padding and retain source pixels.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = "ABank/Assets.xcassets/ABCImported/Loose/Main/abc_resource_ABCFortune_YeJiJiZhun_Arrowdown_Img_393d4b8dcafc.imageset/image.png"
let raw = try Data(contentsOf: root.appendingPathComponent(source))
let image = NSBitmapImageRep(data: raw)!
var left = image.pixelsWide, top = image.pixelsHigh, right = 0, bottom = 0
for y in 0..<image.pixelsHigh {
    for x in 0..<image.pixelsWide where (image.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.01 {
        left = min(left, x); top = min(top, y); right = max(right, x + 1); bottom = max(bottom, y + 1)
    }
}
let crop = CGRect(x: left, y: top, width: right - left, height: bottom - top)
let output = NSBitmapImageRep(cgImage: image.cgImage!.cropping(to: crop)!).representation(using: .png, properties: [:])!
let asset = "abc_account_currency_chevron"
let folder = root.appendingPathComponent("ABank/Assets.xcassets/ABCImported/Account/Original/\(asset).imageset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
try output.write(to: folder.appendingPathComponent("chevron@3x.png"))
let contents: [String: Any] = ["images": [["idiom": "universal", "scale": "3x", "filename": "chevron@3x.png"]], "info": ["author": "xcode", "version": 1], "properties": ["template-rendering-intent": "template"]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
let manifest: [String: Any] = ["asset": asset, "source": source, "source_sha256": SHA256.hash(data: raw).map { String(format: "%02x", $0) }.joined(), "crop": [left, top, right-left, bottom-top], "scale": "3x", "rendering": "template"]
try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]).write(to: root.appendingPathComponent("docs/abc-account-currency-chevron-resource.json"))
print("Imported \(asset): \(right-left)×\(bottom-top) at 3x")
