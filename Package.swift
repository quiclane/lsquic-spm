// swift-tools-version: 6.2
import PackageDescription
let package=Package(name:"lsquic-spm",platforms:[.iOS(.v13)],products:[.library(name:"LSQUIC",targets:["LSQUIC"])],targets:[.binaryTarget(name:"LSQUIC",url:"https://github.com/quiclane/lsquic-spm/releases/download/ios-20260208-9e7c2ba0f865/LSQUIC.xcframework.zip",checksum:"b8af1f54906b28e8a4eca3cc819f878062dbb95cba92185a407409df6ed93aa8")])
