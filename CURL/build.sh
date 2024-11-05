#!/bin/sh

#TODO bootstrap

VERSION=7.76.1


CURL_DIR=${BUILD_DIR}/libcurl

MBEDTLS_DIR=${BUILD_DIR}/mbedtls
MBEDTLS_VERSION=2.27.0

INSTALL_MACOS_DIR=${BUILD_DIR}/distro/macos
INSTALL_IOS_DIR=${BUILD_DIR}/distro/ios/

function prepare() {
    git clone -n git@github.com:ARMmbed/mbedtls ${MBEDTLS_DIR}
    git -C ${MBEDTLS_DIR} checkout v${MBEDTLS_VERSION} || fail "coud not checkout mbedtls branch"
 
    git clone -n git@github.com:curl/curl.git ${CURL_DIR}
    git -C ${CURL_DIR} checkout curl-${_VERSION_} || fail "coud not checkout libcurl branch"
}

function build_macos() {

    # mbed tls -- for macOS (x86_64 arm64)
    cmake -B mbed-macOS -S mbedtls -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 -DCMAKE_OSX_ARCHITECTURES="${MACOS_ARCHS[*]// /;}" -DCMAKE_INSTALL_PREFIX="${INSTALL_MACOS_DIR}" \
      -DMBEDTLS_FATAL_WARNINGS=NO -DENABLE_TESTING=NO -DENABLE_PROGRAMS=NO -GXcode
    cmake --build mbed-macOS --target install --config Release -j1 || fail "mbed-macOS"

    # libcurl -- for macOS (x86_64 arm64), relies on mbed tls

    cmake -B libcurl-macOS -S libcurl -DBUILD_SHARED_LIBS=NO -DCMAKE_USE_SECTRANSP=ON -DCMAKE_USE_MBEDTLS=ON -DBUILD_CURL_EXE=NO -DHTTP_ONLY=ON \
     -DMBEDTLS_INCLUDE_DIRS="${INSTALL_MACOS_DIR}/include" -DCMAKE_INSTALL_PREFIX="${INSTALL_MACOS_DIR}" \
     -DCMAKE_OSX_ARCHITECTURES="${MACOS_ARCHS[*]// /;}" -DCMAKE_OSX_DEPLOYMENT_TARGET=10.9 -GXcode        
    cmake --build libcurl-macOS --target install --config Release || fail "libcurl-macOS"

    install_libraries --platform macosx ${INSTALL_MACOS_DIR}/lib/
    install_headers ${INSTALL_MACOS_DIR}/include/curl
}

function build_ios() {
    #libcurl -- for iOS (arm64)
    cmake -B libcurl-iphoneos -S libcurl "-DCMAKE_OSX_ARCHITECTURES=arm64;${IOS_SIM_ARCHS[*]// /;}" -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
      -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_DIR}/ios.toolchain.cmake" -DCMAKE_INSTALL_PREFIX="${INSTALL_IOS_DIR}"\
      -DHTTP_ONLY=ON -DBUILD_CURL_EXE=NO -DCMAKE_USE_SECTRANSP=ON -DBUILD_SHARED_LIBS=NO -GXcode 
    cmake --build libcurl-iphoneos --config Release --target install || fail "iphoneos build"

    # libcurl -- for iphonesimualtor (x86_64)
    cmake -B libcurl-iphonesim -S libcurl "-DCMAKE_OSX_ARCHITECTURES=${IOS_SIM_ARCHS[*]// /;}" -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
      -DCMAKE_TOOLCHAIN_FILE="${TOOLCHAIN_DIR}/ios.toolchain.cmake" -DPLATFORM=SIMULATOR64 \
      -DHTTP_ONLY=ON -DBUILD_CURL_EXE=NO -DCMAKE_USE_SECTRANSP=ON -DBUILD_SHARED_LIBS=NO -GXcode 
    cmake --build libcurl-iphonesim --config Release || fail "iphonesimulator build"

    # install libraries
    install_libraries --platform iphoneos libcurl-iphoneos/lib/Release-iphoneos/libcurl.a
    install_libraries --platform iphonesimulator libcurl-iphonesim/lib/Release-iphonesimulator/libcurl.a

    install_headers ${INSTALL_IOS_DIR}/include/curl

}

function build() {
    if [ -n "$BUILD_IOS" ]; then
       build_ios
    fi

    if [ -n "$BUILD_MACOS" ]; then
       build_macos
    fi
}
