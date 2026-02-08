lsquic-spm
==========

Deterministic, auto-updating **LSQUIC** binary distribution for Apple platforms,
packaged as a **Swift Package Manager** binary XCFramework.

This repo exists to turn one of the most powerful (and most painful) QUIC stacks
to build into a one-line, paste-and-go dependency for Xcode.

Goal
----

• build LSQUIC correctly for iOS (device + simulator)  
• link it against a known-good TLS backend (BoringSSL)  
• package everything as a single XCFramework  
• ship via SwiftPM with checksum verification  
• auto-update from upstream with traceability  

Paste URL → works.

What LSQUIC is (plain English)
------------------------------

LSQUIC is an open-source **QUIC + HTTP/3** implementation originally developed by
LiteSpeed Technologies.

In practice, it gives you:

- QUIC transport (UDP-based, TLS 1.3 only)
- HTTP/3 support
- Extremely high-performance networking primitives
- Production-proven behavior at scale

If nghttp2 is the gold standard for HTTP/2,
LSQUIC is one of the most serious real-world QUIC implementations available.

It is *not* a toy library.
It is also *not* friendly to build.

Why this repo exists (the real problem)
---------------------------------------

LSQUIC sits at the intersection of multiple hard problems:

1) QUIC requires TLS, but **not OpenSSL**
   - LSQUIC expects BoringSSL-style APIs
   - OpenSSL compatibility layers are incomplete and risky

2) LSQUIC depends on multiple upstream projects
   - lsquic itself
   - BoringSSL
   - nghttp2 (for certain HTTP/3 integration paths)

3) Build system complexity
   - CMake + custom scripts
   - lots of platform feature detection
   - assumptions about Linux / BSD environments

4) Apple platforms complicate everything
   - iOS device vs simulator split
   - arm64 vs x86_64
   - static-only linking is usually required
   - strict XCFramework layout rules

5) SwiftPM binaryTarget is unforgiving
   - URLs must be stable
   - checksums must match exactly
   - artifacts must be self-contained

So if you have ever thought:
“why can’t I just use QUIC in my iOS app?”

This repo is the answer.

What this repo ships
--------------------

- A prebuilt `LSQUIC.xcframework`
- Static libraries only
- Headers arranged consistently for Apple toolchains
- SwiftPM `binaryTarget`
- GitHub Releases-hosted `.xcframework.zip`
- SHA-256 checksum enforced by SwiftPM

No local compilation.
No shell scripts.
No Homebrew requirements.

Upstream trust + integrity model
--------------------------------

This repo tracks LSQUIC’s upstream repository and integrates it with
a pinned, verified BoringSSL build.

Trust is enforced in layers:

1) Known-good crypto base
   - LSQUIC is built *against* the corresponding `boringssl-spm` output
   - crypto/TLS behavior is consistent and deterministic

2) Clean rebuilds
   - GitHub Actions rebuild everything from scratch
   - no reuse of precompiled artifacts

3) Immutable release tags
   - each build is published as:

     ios-YYYYMMDD-<short-hash>

   This represents:
   - upstream LSQUIC state
   - upstream BoringSSL state
   - the exact XCFramework artifact produced

4) SwiftPM checksum verification
   - SwiftPM refuses to load the binary if the checksum mismatches
   - prevents tampering or silent replacement

This means:
- upstream correctness
- downstream integrity
- zero trust placed in local environments

How to use in Xcode
-------------------

1. Open your Xcode project
2. File → Add Package Dependencies…
3. Paste:

   https://github.com/quiclane/lsquic-spm.git

4. Version rule:
   - Choose **Up to Next Major**
   - Enter **1.0.0**

Xcode will:
- fetch the release
- verify the checksum
- link the XCFramework

Done.

Typical dependency stack
------------------------

LSQUIC does not exist in isolation.

Common combinations:

- boringssl-spm  
- nghttp2-spm  
- lsquic-spm  

This gives you:
- TLS 1.3 (BoringSSL)
- HTTP/2 (nghttp2)
- QUIC + HTTP/3 (LSQUIC)

All as deterministic binary packages.

Why versioning looks unusual
----------------------------

You will see tags like:

- ios-20260208-9fa31c2b8d41

These are **build identity tags**.
They encode:
- build date
- upstream state fingerprint

SwiftPM, however, expects semantic versions.

So we use a pointer strategy:

- `1.0.0` → stable pointer (recommended)
- `1.0.1` → fresh pointer (newer build)

These semantic tags are updated to point at newer immutable build tags over time.

Important:
- SwiftPM still verifies the binary via checksum
- the pointer does not weaken integrity

Think of `1.0.0` as:
“always give me the latest known-good LSQUIC build”.

Why LSQUIC is especially hard to package
----------------------------------------

LSQUIC is hard because QUIC is hard.

Specifically:

- QUIC is UDP-based but encrypted
- TLS is mandatory and deeply integrated
- handshake logic is transport-aware
- timing, retransmission, and congestion logic are intertwined

This makes:
- ABI mismatches disastrous
- header/library inconsistencies fatal
- partial rebuilds unreliable

Apple’s platform rules add:
- strict symbol visibility
- strict slice alignment
- no dynamic loading on iOS

This repo solves all of that once, centrally.

Guarantees
----------

- Static linking only
- AppleClang-compatible builds
- iOS device + simulator slices
- SwiftPM checksum enforcement
- No local build steps for users
- Deterministic, reproducible artifacts

Related repos
-------------

- https://github.com/quiclane/boringssl-spm
- https://github.com/quiclane/nghttp2-spm

License
-------

LSQUIC is licensed by LiteSpeed Technologies.
This repo redistributes binaries built from upstream source.
See upstream LSQUIC licensing for details.
