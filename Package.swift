// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "ApplinIos",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "ApplinIos", targets: ["ApplinIos"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "ApplinIos", dependencies: []),
        // TODONT: Do not add test targets, since `swift test` always fails
        //         with `error: no such module 'UIKit'`.  We test with XCode.
    ]
)
