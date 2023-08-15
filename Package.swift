// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "ApplinIos",
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
