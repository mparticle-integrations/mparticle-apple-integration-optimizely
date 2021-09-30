// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "mParticle_Optimizely",
    platforms: [ .iOS(.v10) ],
    products: [
        .library(
            name: "mParticle_Optimizely",
            targets: ["mParticle_Optimizely"]),
    ],
    dependencies: [
      .package(name: "mParticle-Apple-SDK",
               url: "https://github.com/mParticle/mparticle-apple-sdk",
               .upToNextMajor(from: "8.0.0")),
      .package(name: "Optimizely",
               url: "https://github.com/optimizely/swift-sdk.git",
               .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
        .target(
            name: "mParticle_Optimizely",
            dependencies: ["mParticle-Apple-SDK","Optimizely"],
            path: "mParticle_Optimizely",
            publicHeadersPath: "."),
    ]
)
