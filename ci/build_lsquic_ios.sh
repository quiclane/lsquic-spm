#!/bin/sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/_work"
UP="$ROOT/_upstream"
OUT="$ROOT/build-out"
IOS_MIN="13.0"

mkdir -p "$WORK" "$UP" "$OUT"
rm -rf "$WORK"/*

need(){ command -v "$1" >/dev/null 2>&1 || { echo "MISSING:$1"; exit 1; }; }
need git; need cmake; need ninja; need xcrun; need xcodebuild; need lipo; need libtool; need zip

BORING_REPO="https://boringssl.googlesource.com/boringssl"
LSQUIC_REPO="https://github.com/litespeedtech/lsquic.git"
LSQUIC_BRANCH="master"

echo "==clone=="
rm -rf "$UP/boringssl" "$UP/lsquic"
git clone --depth 1 "$BORING_REPO" "$UP/boringssl"
git clone --depth 1 --branch "$LSQUIC_BRANCH" "$LSQUIC_REPO" "$UP/lsquic"

BORING_SRC="$UP/boringssl"
LSQUIC_SRC="$UP/lsquic"

SDKP="$(xcrun --sdk iphoneos --show-sdk-path)"
SDKS="$(xcrun --sdk iphonesimulator --show-sdk-path)"

build_boringssl_one(){
  PLAT="$1"; ARCHS="$2"; SDK="$3"; BDIR="$4"
  rm -rf "$BDIR"; mkdir -p "$BDIR"
  cmake -S "$BORING_SRC" -B "$BDIR" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$SDK" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_MIN" \
    -DBUILD_SHARED_LIBS=0
  cmake --build "$BDIR"
}

echo "==boringssl build=="
B_IOS="$WORK/boring_ios_arm64"
B_SIM="$WORK/boring_sim_universal"
build_boringssl_one ios "arm64" "$SDKP" "$B_IOS"
build_boringssl_one sim "arm64;x86_64" "$SDKS" "$B_SIM"

combine_boringssl(){
  BDIR="$1"; OUTA="$2"
  SSL="$BDIR/ssl/libssl.a"
  CRY="$BDIR/crypto/libcrypto.a"
  test -f "$SSL"
  test -f "$CRY"
  libtool -static -o "$OUTA" "$SSL" "$CRY"
}

mkdir -p "$WORK/boring_out"
BORING_IOS_A="$WORK/boring_out/libboringssl_ios.a"
BORING_SIM_A="$WORK/boring_out/libboringssl_sim.a"
combine_boringssl "$B_IOS" "$BORING_IOS_A"
combine_boringssl "$B_SIM" "$BORING_SIM_A"
BORING_INC="$BORING_SRC/include"

echo "==lsquic build=="
build_lsquic_one(){
  NAME="$1"; ARCHS="$2"; SDK="$3"; BORING_A="$4"; ODIR="$5"
  rm -rf "$ODIR"; mkdir -p "$ODIR"
  cmake -S "$LSQUIC_SRC" -B "$ODIR" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=0 \
    -DLSQUIC_SHARED_LIB=0 \
    -DLSQUIC_BUILD_TESTS=0 \
    -DLSQUIC_BUILD_EXAMPLES=0 \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$SDK" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCHS" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_MIN" \
    -DBORINGSSL_INCLUDE_DIR="$BORING_INC" \
    -DBORINGSSL_LIBRARIES="$BORING_A"
  cmake --build "$ODIR"
}

L_IOS="$WORK/lsquic_ios_arm64"
L_SIM="$WORK/lsquic_sim_universal"
build_lsquic_one ios "arm64" "$SDKP" "$BORING_IOS_A" "$L_IOS"
build_lsquic_one sim "arm64;x86_64" "$SDKS" "$BORING_SIM_A" "$L_SIM"

find_liblsquic(){
  base="$1"
  f="$(find "$base" -type f -name 'liblsquic.a' -print | head -n 1 || true)"
  test -n "${f:-}"
  echo "$f"
}

LIB_IOS="$(find_liblsquic "$L_IOS")"
LIB_SIM="$(find_liblsquic "$L_SIM")"

echo "==headers stage=="
HDR="$WORK/headers"
rm -rf "$HDR"; mkdir -p "$HDR"
cp -R "$LSQUIC_SRC/include" "$HDR/include"

echo "==xcframework=="
rm -rf "$OUT/LSQUIC.xcframework" "$OUT/LSQUIC.xcframework.zip"
xcodebuild -create-xcframework \
  -library "$LIB_IOS" -headers "$HDR/include" \
  -library "$LIB_SIM" -headers "$HDR/include" \
  -output "$OUT/LSQUIC.xcframework"

cd "$ROOT"
zip -r "$OUT/LSQUIC.xcframework.zip" "build-out/LSQUIC.xcframework" >/dev/null
test -f "$OUT/LSQUIC.xcframework.zip"
echo "OK: $OUT/LSQUIC.xcframework.zip"
