// swift-tools-version:5.9
import PackageDescription
let package=Package(name:"lsquic-spm",products:[.library(name:"LSQUIC",targets:["LSQUIC"])],targets:[.binaryTarget(name:"LSQUIC",url:"https://github.com/quiclane/lsquic-spm/releases/download/v0.0.1/LSQUIC.xcframework.zip",checksum:"0000000000000000000000000000000000000000000000000000000000000000")])
