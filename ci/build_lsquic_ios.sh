#!/bin/sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/_work"
OUT="$ROOT/build-out"
XCF="${BORING_XCF:-$HOME/Desktop/boringssl-spm/build-out/BoringSSL.xcframework}"

IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
SIM_SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"

rm -rf "$WORK" "$OUT"
mkdir -p "$WORK" "$OUT"

echo "== check boringssl xcframework =="
test -d "$XCF"
test -f "$XCF/ios-arm64/Headers/openssl/ssl.h"
test -f "$XCF/ios-arm64/libboringssl_ios_arm64.a"
test -f "$XCF/ios-arm64_x86_64-simulator/libboringssl_sim.a"
echo "OK XCF=$XCF"

thin_boringssl() {
  arch="$1"
  plat="$2"
  mkdir -p "$WORK/boringssl_thin"
  if [ "$plat" = "ios" ]; then
    in="$XCF/ios-arm64/libboringssl_ios_arm64.a"
    out="$WORK/boringssl_thin/boringssl_ios_${arch}.a"
    cp -f "$in" "$out"
  else
    in="$XCF/ios-arm64_x86_64-simulator/libboringssl_sim.a"
    out="$WORK/boringssl_thin/boringssl_sim_${arch}.a"
    lipo -thin "$arch" "$in" -output "$out"
  fi
  printf "%s" "$out"
}

echo "== clone lsquic =="
git clone --depth 1 --recurse-submodules "$(awk -F= '/^repo=/{print $2}' "$ROOT/ci/lsquic-upstream.txt" | tail -n 1)" "$WORK/lsquic"

build_one() {
  name="$1"; sdk="$2"; arch="$3"; plat="$4"
  bdir="$WORK/build-$name"
  rm -rf "$bdir"
  mkdir -p "$bdir"
  cd "$bdir"

  BORING_INC="$XCF/ios-arm64/Headers"
  BORING_LIB="$(thin_boringssl "$arch" "$plat")"

  export EXTRA_CFLAGS="-Wno-unused-but-set-variable -Wno-unused-function"
  export EXTRA_CXXFLAGS="-Wno-unused-but-set-variable -Wno-unused-function"

  cmake -G Ninja "$WORK/lsquic" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$sdk" \
    -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DBORINGSSL_INCLUDE="$BORING_INC" \
    -DBORINGSSL_LIB_ssl="$BORING_LIB" \
    -DBORINGSSL_LIB_crypto="$BORING_LIB" \
    -DLSQUIC_TESTS=OFF \
    -DLSQUIC_BIN=OFF

  ninja
}

echo "== build ios arm64 =="
build_one ios-arm64 "$IOS_SDK" arm64 ios

echo "== build sim arm64 =="
build_one sim-arm64 "$SIM_SDK" arm64 sim

echo "== build sim x86_64 =="
build_one sim-x86_64 "$SIM_SDK" x86_64 sim

IOS_LIB="$WORK/build-ios-arm64/src/liblsquic/liblsquic.a"
SIM_ARM64_LIB="$WORK/build-sim-arm64/src/liblsquic/liblsquic.a"
SIM_X86_LIB="$WORK/build-sim-x86_64/src/liblsquic/liblsquic.a"

echo "== lipo sim =="
mkdir -p "$OUT/sim-fat"
lipo -create "$SIM_ARM64_LIB" "$SIM_X86_LIB" -output "$OUT/sim-fat/liblsquic.a"

echo "== create xcframework =="
xcodebuild -create-xcframework \
  -library "$IOS_LIB" -headers "$WORK/lsquic/include" \
  -library "$OUT/sim-fat/liblsquic.a" -headers "$WORK/lsquic/include" \
  -output "$OUT/LSQUIC.xcframework"

echo "== zip =="
rm -f "$OUT/LSQUIC.xcframework.zip"
( cd "$OUT" && /usr/bin/zip -r "LSQUIC.xcframework.zip" "LSQUIC.xcframework" >/dev/null )

ls -la "$OUT/LSQUIC.xcframework" "$OUT/LSQUIC.xcframework.zip"
