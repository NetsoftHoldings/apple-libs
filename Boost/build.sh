#!/bin/bash

VERSION=1.58.0

APPLE_BUILD_SCRIPT_DIR="${BUILD_DIR}/Apple-Boost-BuildScript"
ANDROID_DIR="${BUILD_DIR}/Boost-For-Android"

function prepare() {
    BOOST_TARBALL="${BUILD_DIR}/boost_${VERSION//./_}.tar.bz2"
    BOOST_SRC="${BUILD_DIR}/boost_${VERSION//./_}"

    if [ -n "${BUILD_IOS}" ] || [ -n "${BUILD_MACOS}" ]; then
        git clone https://github.com/paynerc/Apple-Boost-BuildScript.git ${APPLE_BUILD_SCRIPT_DIR}

        git -C ${APPLE_BUILD_SCRIPT_DIR} checkout add_arm64_simulator_support

        patch ${APPLE_BUILD_SCRIPT_DIR} Apple-Boost-BuildScript.patch
    fi

    if [ -n "${BUILD_ANDROID}" ]; then
        git clone https://github.com/moritz-wundke/Boost-for-Android.git ${ANDROID_DIR}

        if patch ${ANDROID_DIR} Boost-for-Android.patch -t -s --force --reverse --dry-run; then
            echo "Patch already applied"
        else 
            patch ${ANDROID_DIR} Boost-for-Android.patch -t  || fail "Cannot apply Boost-for-Android.patch"
        fi
    fi

    if [ -n "${BUILD_LINUX}" ]; then
        if ! command -v g++; then
            fail "gcc-c++ is not installed, aborting"
        elif ! command -v bzip2 &> /dev/null; then
            fail "bzip2 is not installed, aborting"
        elif [ ! -f /usr/include/bzlib.h ]; then
            fail "bzip2-devel is not installed, aborting"
        fi
        if [ "$(version "${VERSION}")" -ge $(version "1.63") ]; then
            DOWNLOAD_SRC=https://boostorg.jfrog.io/artifactory/main/release/${VERSION}/source/boost_${VERSION//./_}.tar.bz2
        else
            DOWNLOAD_SRC=http://sourceforge.net/projects/boost/files/boost/${VERSION}/boost_${VERSION//./_}.tar.bz2/download
        fi

        if [ ! -s "${BOOST_TARBALL}" ]; then
            curl -L -o "${BOOST_TARBALL}" "${DOWNLOAD_SRC}"
        fi
        
        [ -d "${BUILD_DIR}" ] || mkdir -p "${BUILD_DIR}"
        [ -d "${BOOST_SRC}" ] || (cd ${BUILD_DIR} && tar xjf ${BOOST_TARBALL})
    fi
}

#BASE_BOOST_LIBS="atomic chrono date_time exception filesystem iostreams locale random regex serialization system thread"

function build_apple() {
    pushd ${APPLE_BUILD_SCRIPT_DIR}
    ./boost.sh --min-ios-version 9.0 --boost-version ${VERSION} --min-macos-version 10.9 \
	--boost-libs "atomic chrono date_time exception filesystem iostreams locale random regex serialization system thread program_options" \
	--ios-archs "armv7 arm64" --macos-archs "${MACOS_ARCHS[*]}" "$@"
    local RESULT=$?
    popd
    return ${RESULT}
}

function build_ios() {
    build_apple -ios || fail "ios libraries failed to build"

    install_libraries --platform iphoneos "${IOS_LIBS}"
    install_libraries --platform iphonesimulator "${IOS_SIM_LIBS}"
    install_headers ${IOS_HEADERS}
}

function build_macos() {
    build_apple -macos || fail "ios libraries failed to build"

    install_libraries --platform macos "${MACOS_LIBS}"
    install_headers ${MACOS_HEADERS}
}

function build_android() {
    pushd ${ANDROID_DIR}
    
    local ANDROID_BUILD_DIR=${ANDROID_DIR}/build/out/
    local ANDROID_HEADERS=${ANDROID_BUILD_DIR}/${ANDROID_ARCHS[0]}/include/boost

    local ARCHS="${ANDROID_ARCHS[*]}"

    ./build-android.sh --boost=${VERSION} --layout=system --arch=${ARCHS// /,} --with-libraries=atomic,chrono,date_time,exception,filesystem,iostreams,random,regex,serialization,system,thread

    for ARCH in ${ANDROID_ARCHS[@]};do
        install_libraries --platform android/${ARCH}        "${ANDROID_BUILD_DIR}/${ARCH}/lib"
    done
#    install_libraries --platform android/x86_64     "${ANDROID_BUILD_DIR}/x86_64/lib"
#    install_libraries --platform android/armabi-v7a "${ANDROID_BUILD_DIR}/armeabi-v7a/lib"
#    install_libraries --platform android/arm64-v8a  "${ANDROID_BUILD_DIR}/arm64-v8a/lib"
    install_headers ${ANDROID_HEADERS}

    popd
}

function build_linux() {
    pushd ${BOOST_SRC}

    BOOST_LIBS="atomic chrono date_time exception filesystem iostreams locale random regex serialization system thread program_options"

    LINUX_LIBS="${BOOST_SRC}/build/prefix/lib"
    LINUX_HEADERS="${BOOST_SRC}/build/prefix/include/boost"

    ./bootstrap.sh --with-toolset=gcc --without-icu \
        --with-libraries="${BOOST_LIBS// /,}" \
        || fail "bootstrap failed"

     echo "Building boost for linux"

    ./b2 --build-dir=./build \
        --stagedir=./build/stage \
        --prefix=./build/prefix \
        cflags="-fPIC" \
        cxxflags="-fPIC -std=c++14 -D_GLIBCXX_USE_CXX11_ABI=0" \
        variant=release \
        threading=multi \
        debug-symbols=off \
        pch=off \
        link=static \
        -d2 \
        install > build.log 2>&1 || fail "Error building linux. Check log"

    install_libraries --platform linux "${LINUX_LIBS}"
    install_headers "${LINUX_HEADERS}"

    popd
}

function build() {
    BOOST_BUILD_DIR="${APPLE_BUILD_SCRIPT_DIR}/build/boost/${VERSION}"
    IOS_LIBS="${BOOST_BUILD_DIR}/ios/release/prefix/lib"
    IOS_HEADERS="${BOOST_BUILD_DIR}/ios/release/prefix/include/boost"
    IOS_SIM_LIBS="${APPLE_BUILD_SCRIPT_DIR}/src/boost_${_VERSION_}/iphonesim-build/stage/lib"
    MACOS_LIBS="${BOOST_BUILD_DIR}/macos/release/prefix/lib"
    MACOS_HEADERS="${BOOST_BUILD_DIR}/macos/release/prefix/include/boost"

    if [ -n "${BUILD_IOS}" ]; then
       build_ios
    fi

    if [ -n "${BUILD_MACOS}" ]; then
       build_macos
    fi

    if [ -n "${BUILD_ANDROID}" ]; then
       build_android
    fi

    if [ -n "${BUILD_LINUX}" ]; then
       build_linux
    fi
}
