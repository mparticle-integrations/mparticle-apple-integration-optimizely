// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
let package = Package(
    name: "mParticle-Optimizely",
    platforms: [ .iOS(.v10), .tvOS(.v10) ],
    products: [
        .library(
            name: "mParticle-Optimizely",
            targets: ["mParticle_Optimizely"]),
    ],
    dependencies: [
      .package(name: "mParticle-Apple-SDK",
               url: "https://github.com/mParticle/mparticle-apple-sdk",
               .upToNextMajor(from: "8.22.0")),
      .package(name: "Optimizely",
               url: "https://github.com/optimizely/swift-sdk",
               .upToNextMajor(from: "4.0.0")),
    ],
    targets: [
        .target(
            name: "mParticle_Optimizely",
            dependencies: ["mParticle-Apple-SDK", "Optimizely"],
            path: "mParticle_Optimizely",
            resources: [.process("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."
        ),
    ]
)
