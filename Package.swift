// swift-tools-version: 6.2
import PackageDescription
let package=Package(name:"lsquic-spm",platforms:[.iOS(.v13)],products:[.library(name:"LSQUIC",targets:["LSQUIC"])],targets:[.binaryTarget(name:"LSQUIC",path:"LSQUIC.xcframework")])
