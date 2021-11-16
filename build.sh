#!/bin/sh

LIB="freetds"
VERSION=1.00.15
TDS_VERSION=7.4
BASE_PATH=`pwd`
BUILD="x86_64-apple-darwin21"
DEVELOPER=`xcode-select -print-path`
PLATFORMS="MacOSX iPhoneOS iPhoneSimulator WatchOS WatchSimulator AppleTVOS AppleTVSimulator"
#PLATFORMS="AppleTVOS AppleTVSimulator"
#PLATFORMS="MacOSX"

pushd ${LIB}-${VERSION}
for PLATFORM in ${PLATFORMS}
do
  case "${PLATFORM}" in
    "MacOSX"|"iPhoneSimulator"|"WatchSimulator"|"AppleTVSimulator")
      ARCHS="i386 x86_64 arm64"
      ;;
    "iPhoneOS")
      ARCHS="arm64 arm64e"
      ;;
    "WatchOS")
      ARCHS="armv7k arm64_32"
      ;;
    "AppleTVOS")
      ARCHS="arm64"
      ;;
  esac

  for ARCH in ${ARCHS}
  do
    case "${ARCH}" in
      "arm64"|"arm64e")
        HOST="aarch64-apple-darwin20"
        ;;
      *)
        HOST="${ARCH}-apple-darwin20"
        ;;
    esac
    
    SDK="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}.sdk"
    export CC="clang"
    export CFLAGS="-arch ${ARCH} -isysroot ${SDK} -fembed-bitcode" # -miphoneos-version-min=15.0
    export CXXFLAGS="$CFLAGS"
    export LDFLAGS="$CFLAGS"
    export LD=$CC
    export ENABLE_BITCODE=YES
    PREFIX="${BASE_PATH}/build/${PLATFORM}/${ARCH}"
    echo ${PREFIX}
    mkdir -p ${PREFIX}
    echo ./configure --disable-apps --disable-server --disable-pool --disable-libiconv --prefix=$PREFIX --host=${HOST} --build=${BUILD} --with-tdsver=${TDS_VERSION} CFLAGS="${CFLAGS}"
    ./configure --disable-apps --disable-server --disable-pool --disable-libiconv --prefix=$PREFIX --host=${HOST} --build=${BUILD} --with-tdsver=${TDS_VERSION} CFLAGS="${CFLAGS}" && \
    make clean && make && make install
    echo "======== CHECK ARCH ========"
    xcrun -sdk iphoneos lipo -info ${PREFIX}/lib/libsybdb.a
  done
done
popd

exit

find build -name libsybdb.a -exec lipo -info {} \;

lipo -create \
  build/MacOSX/*/lib/libsybdb.a \
  -output build/MacOSX/libsybdb.a

lipo -create \
  build/iPhoneOS/*/lib/libsybdb.a \
  -output build/iPhoneOS/libsybdb.a

lipo -create \
  build/iPhoneSimulator/*/lib/libsybdb.a \
  -output build/iPhoneSimulator/libsybdb.a

lipo -create \
  build/WatchSimulator/*/lib/libsybdb.a \
  -output build/WatchSimulator/libsybdb.a

lipo -create \
  build/AppleTVSimulator/*/lib/libsybdb.a \
  -output build/AppleTVSimulator/libsybdb.a

xcodebuild -create-xcframework \
  -library build/MacOSX/libsybdb.a \
  -headers build/MacOSX/arm64/include \
  -library build/iPhoneOS/libsybdb.a \
  -headers build/iPhoneOS/arm64/include \
  -library build/iPhoneSimulator/libsybdb.a \
  -headers build/iPhoneSimulator/arm64/include \
  -library build/WatchOS/armv7k/lib/libsybdb.a \
  -headers build/WatchOS/armv7k/include \
  -library build/WatchSimulator/libsybdb.a \
  -headers build/WatchSimulator/arm64/include \
  -library build/AppleTVOS/arm64/lib/libsybdb.a \
  -headers build/AppleTVOS/arm64/include \
  -library build/AppleTVSimulator/libsybdb.a \
  -headers build/AppleTVSimulator/arm64/include \
  -output libsybdb.xcframework
