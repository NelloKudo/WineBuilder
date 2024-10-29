#!/usr/bin/env bash

set -euo pipefail

Info() {
    echo -e '\033[1;34m'"WineBuilder:\033[0m $*"
}

Error() {
    echo -e '\033[1;31m'"WineBuilder:\033[0m $*"
    exit 1
}

## -------------------------------------------------------
##              WineBuilder Docker Settings
## -------------------------------------------------------

# Base paths
WINE_ROOT="/wine"
BUILD_DIR="${WINE_ROOT}/build_wine"
SOURCE_DIR="${WINE_ROOT}/sources"

# Wine version settings
WINE_VERSION="${WINE_VERSION:-3a736901cdd588ba7fbb4318e5f5069793268a01}"
STAGING_VERSION="${STAGING_VERSION:-78bd3f0c6d0beb781b87dd9d54fd186e8f7628ef}"
WINE_BRANCH="winello"
RELEASE_VERSION="${RELEASE_VERSION:-}"

# Patchset configuration: use remote:latest to use latest tag matching tag filter, remote:<tag> to use chosen tag
PATCHSET="remote:latest" # leave empty for loose patches in custompatches/
PATCHSET_REPO="${PATCHSET_REPO:-https://github.com/whrvt/wine-osu-patches.git}"
TAG_FILTER="${TAG_FILTER:-winello*}"

# Build configuration
USE_WOW64="${USE_WOW64:-true}"
STAGING_ARGS="${STAGING_ARGS:---all}"

## ------------------------------------------------------------
##                      Build Setup
## ------------------------------------------------------------

if [ "$USE_WOW64" = "true" ]; then WOW_NAME="-wow64"; fi
BUILD_OUT_TMP_DIR="wine-${WINE_BRANCH}-build"

# Ensure source directory exists
mkdir -p "${SOURCE_DIR}"

WINE_BUILD_OPTIONS=(
    --prefix="${BUILD_DIR}/${BUILD_OUT_TMP_DIR}"
    --disable-tests
    --with-x
    --with-gstreamer
    --with-wayland
    --enable-silent-rules
    --without-oss
    --without-coreaudio
    --without-cups
    --without-sane
)

# Configure WoW64 build options
if [ "${USE_WOW64}" = "true" ]; then
    WINE_64_BUILD_OPTIONS=(
        --enable-archs="x86_64,i386"
        --libdir="${BUILD_DIR}/${BUILD_OUT_TMP_DIR}/lib64"
    )
else
    WINE_64_BUILD_OPTIONS=(
        --enable-win64
        --libdir="${BUILD_DIR}/${BUILD_OUT_TMP_DIR}/lib64"
    )
fi

WINE_32_BUILD_OPTIONS=(
    --libdir="${BUILD_DIR}/${BUILD_OUT_TMP_DIR}/lib"
    --with-wine64="${BUILD_DIR}/build64"
)

## ------------------------------------------------------------
##                  Compiler Configuration
## ------------------------------------------------------------

# LLVM-MinGW configuration
export LLVM_MINGW_PATH="/usr/local/llvm-mingw"
export PATH="${LLVM_MINGW_PATH}/bin:${PATH}"

# Compiler flags
export CPPFLAGS="-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -DNDEBUG -D_NDEBUG"
_common_cflags="-march=x86-64 -mtune=generic -msse -msse2 -static-libgcc -static-libstdc++ -pipe -Oz -mfpmath=sse -fno-strict-aliasing \
                -fomit-frame-pointer -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration -Wno-error=int-conversion -w"
_native_common_cflags=""

_GCC_FLAGS="${_common_cflags} ${_native_common_cflags} ${CPPFLAGS}"
_LD_FLAGS="${_GCC_FLAGS} -Wl,-O2,--sort-common,--as-needed"

_CROSS_FLAGS="${_common_cflags} ${CPPFLAGS}"
_CROSS_LD_FLAGS="${_CROSS_FLAGS} -Wl,/FILEALIGN:4096,/OPT:REF,/OPT:ICF"

# Compiler settings
export CC="ccache clang"
export CXX="ccache clang++"
export CROSSCC="ccache clang"
export CROSSCC_X32="ccache clang"
export CROSSCXX_X32="ccache clang++"
export CROSSCC_X64="ccache clang"
export CROSSCXX_X64="ccache clang++"

export i386_CC="${CROSSCC_X32}"
export x86_64_CC="${CROSSCC_X64}"

# Compiler and linker flags
export CFLAGS="${_GCC_FLAGS}"
export CXXFLAGS="${_GCC_FLAGS}"
export LDFLAGS="${_LD_FLAGS}"

export CROSSCFLAGS="${_CROSS_FLAGS}"
export CROSSCXXFLAGS="${_CROSS_FLAGS}"
export CROSSLDFLAGS="${_CROSS_LD_FLAGS}"

WINE_64_BUILD_OPTIONS+=(--with-mingw="$CROSSCC_X64")
WINE_32_BUILD_OPTIONS+=(--with-mingw="$CROSSCC_X32")

## ------------------------------------------------------------
##                  Patch Management
## ------------------------------------------------------------

# Initialize patch logging
rm -f "${WINE_ROOT}/patches.log"

if [ -n "${PATCHSET}" ]; then
    Info "Patchset" "${PATCHSET}"
    patches_dir="${WINE_ROOT}/patchset-current"
    rm -rf "${patches_dir}"
    mkdir -p "${patches_dir}"

    if [ "${PATCHSET:0:7}" = "remote:" ]; then
        _git_tag="${PATCHSET:7}"
        cd "${patches_dir}"

        git init
        git config advice.detachedHead false
        git remote add origin "${PATCHSET_REPO}"
        git fetch || Error "Invalid patchset repository URL"

        if [ "${_git_tag}" = "latest" ]; then
            _git_tag="$(git ls-remote --sort=-committerdate --tags origin "${TAG_FILTER}" |
                head -n1 | cut -f2 | cut -f3 -d'/')"
            Info "Latest patchset tag: ${_git_tag}"
        fi

        git reset --hard "${_git_tag}" || Error "Invalid patchset tag"

        WINE_VERSION="$(cat "${patches_dir}/wine-commit")"
        STAGING_VERSION="$(cat "${patches_dir}/staging-commit")"

        [ -r "${patches_dir}/staging-exclude" ] && STAGING_ARGS+=" $(cat "${patches_dir}/staging-exclude")"
    else
        tar xf "$(find "${WINE_ROOT}/osu-misc/" -type f -iregex ".*${PATCHSET}.*")" -C "${patches_dir}" ||
            Error "Invalid patchset specified"
    fi
else
    patches_dir="${WINE_ROOT}/custompatches"
fi

## ------------------------------------------------------------
##                  Build Functions
## ------------------------------------------------------------

_staging_patcher() {
    Info "Applying Wine-Staging patches..."

    local staging_patcher
    if [ -f "wine-staging-${WINE_VERSION}/patches/patchinstall.sh" ]; then
        staging_patcher=("${BUILD_DIR}/wine-staging-${WINE_VERSION}/patches/patchinstall.sh"
            DESTDIR="${BUILD_DIR}/wine")
    else
        staging_patcher=("${BUILD_DIR}/wine-staging-${WINE_VERSION}/staging/patchinstall.py")
    fi

    cd "${BUILD_DIR}/wine" || Error "Failed to change to wine source directory"

    # Apply staging overrides if they exist
    if find "${patches_dir}/staging-overrides" -name "*spatch" -print0 -quit | grep . >/dev/null; then
        for override in "${patches_dir}"/staging-overrides/*; do
            base=$(basename "${override}")
            dest=$(find "${BUILD_DIR}/wine-staging-${WINE_VERSION}/patches/" -name "${base%.spatch}*")
            cp "${override}" "${dest}"
        done
        Info "Applied staging patch overrides"
    fi

    if [ -n "${STAGING_ARGS}" ]; then
        "${staging_patcher[@]}" --no-autoconf ${STAGING_ARGS}
    else
        "${staging_patcher[@]}" --no-autoconf --all
    fi || Error "Failed to apply Wine-Staging patches"
}

build_wine() {
    Info "Starting Wine build process..."

    # Setup reproducible build and ensure ccache works
    export SOURCE_DATE_EPOCH=0

    # Prepare build environment
    cd "${BUILD_DIR}"
    rm -rf build64
    mkdir -p build64
    cd build64

    export PKG_CONFIG_LIBDIR="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:${LLVM_MINGW_PATH}/x86_64-w64-mingw32/lib/pkgconfig"
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}"
    export x86_64_CC="${CROSSCC_X64}"
    export i386_CC="${CROSSCC_X32}"
    export CROSSCC="${CROSSCC_X64}"

    if [ -f "/usr/local/lib/libunwind.a" ] && [ -f "/usr/local/lib/liblzma.a" ]; then
        export UNWIND_CFLAGS=""
        export UNWIND_LIBS="-L/usr/local/lib/ -static-libgcc -l:libunwind.a -l:liblzma.a"
    fi

    # Configure and build 64-bit
    "${BUILD_DIR}/wine/configure" "${WINE_BUILD_OPTIONS[@]}" "${WINE_64_BUILD_OPTIONS[@]}"
    make -j"$(nproc)"

    unset UNWIND_CFLAGS UNWIND_LIBS

    # Build 32-bit if not WoW64
    if [ "${USE_WOW64}" != "true" ]; then
        export PKG_CONFIG_LIBDIR="/usr/lib/i386-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/i386-linux-gnu/pkgconfig:/usr/local/i386/lib/i386-linux-gnu/pkgconfig:${LLVM_MINGW_PATH}/i686-w64-mingw32/lib/pkgconfig"
        export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}"
        export CROSSCC="${CROSSCC_X32}"
        export I386_LIBS="-latomic"

        cd "${BUILD_DIR}"
        rm -rf build32
        mkdir build32
        cd build32

        "${BUILD_DIR}/wine/configure" "${WINE_BUILD_OPTIONS[@]}" "${WINE_32_BUILD_OPTIONS[@]}"
        make -j"$(nproc)"
    fi

    unset SOURCE_DATE_EPOCH
}

package_wine() {
    Info "Packaging Wine build..."

    cd "${BUILD_DIR}"

    # Install 32-bit if not WoW64
    if [ "${USE_WOW64}" != "true" ]; then
        cd build32
        make -j"$(nproc)" install-lib
    fi

    # Install 64-bit
    cd "${BUILD_DIR}/build64"
    make -j"$(nproc)" CC=gcc install-lib

    # Strip debug symbols
    find "${BUILD_DIR}/${BUILD_OUT_TMP_DIR}/lib"{,64} \
        -type f '(' -iname '*.a' -o -iname '*.dll' -o -iname '*.so' -o -iname '*.sys' -o -iname '*.drv' -o -iname '*.exe' ')' \
        -print0 | xargs -0 strip --strip-unneeded 2>/dev/null || true

    rm -rf "${BUILD_DIR}/${BUILD_OUT_TMP_DIR}"/{include,share/{applications,man}}

    if [ "${USE_WOW64}" = "true" ]; then
        ln -srf "${BUILD_DIR}/${BUILD_OUT_TMP_DIR}"/bin/wine{,64}
    fi

    # Create final package
    cd "${BUILD_DIR}"
    [ -z "${RELEASE_VERSION}" ] && RELEASE_VERSION="1"

    mv "${BUILD_OUT_TMP_DIR}" "wine-osu"

    Info "Creating and compressing archives..."
    XZ_OPT="-9 -T0 " tar -Jcf "wine-osu-${WINE_BRANCH}-${WINE_VERSION}${WOW_NAME:-}-${RELEASE_VERSION}-x86_64.tar.xz" \
        --xattrs --numeric-owner --owner=0 --group=0 wine-osu
    mv "wine-osu-${WINE_BRANCH}-${WINE_VERSION}-${RELEASE_VERSION}-x86_64.tar.xz" "${WINE_ROOT}"
}

## ------------------------------------------------------------
##                  Main Execution
## ------------------------------------------------------------

main() {
    # Clean previous build directory but keep sources
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}"

    # Set up source directories
    Info "Setting up Wine source code..."
    mkdir -p "${SOURCE_DIR}"

    # Initialize/update Wine source
    if [ ! -d "${SOURCE_DIR}/wine/.git" ]; then
        Info "Cloning Wine repository..."
        cd "${SOURCE_DIR}"
        git clone --bare https://github.com/wine-mirror/wine wine-bare
        git clone wine-bare wine
        cd wine
        git remote set-url origin https://github.com/wine-mirror/wine
    else
        Info "Updating Wine repository..."
        cd "${SOURCE_DIR}/wine"
        git remote set-url origin https://github.com/wine-mirror/wine
        git fetch origin
    fi

    # Clean and reset Wine source
    cd "${SOURCE_DIR}/wine"
    git reset --hard HEAD
    git clean -xdf
    git remote update

    # Checkout specific Wine version if specified
    if [ -n "${WINE_VERSION}" ]; then
        Info "Checking out Wine version: ${WINE_VERSION}"
        git fetch --all --tags
        git checkout "${WINE_VERSION}" || Error "Failed to checkout Wine version ${WINE_VERSION}"
    else
        Info "Using latest Wine version"
        git checkout master
        git pull origin master
    fi
    WINE_VERSION=$(git describe --tags --abbrev=0 | cut -f2 -d'-')
    Info "Building Wine version: ${WINE_VERSION}"

    # Initialize/update Wine-Staging source
    if [ ! -d "${SOURCE_DIR}/wine-staging/.git" ]; then
        Info "Cloning Wine-Staging repository..."
        cd "${SOURCE_DIR}"
        git clone --bare https://github.com/wine-staging/wine-staging wine-staging-bare
        git clone wine-staging-bare wine-staging
        cd wine-staging
        git remote set-url origin https://github.com/wine-staging/wine-staging
    else
        Info "Updating Wine-Staging repository..."
        cd "${SOURCE_DIR}/wine-staging"
        git remote set-url origin https://github.com/wine-staging/wine-staging
        git fetch origin
    fi

    # Clean and reset Wine-Staging source
    cd "${SOURCE_DIR}/wine-staging"
    git reset --hard HEAD
    git clean -xdf
    git remote update

    # Checkout specific Staging version if specified
    if [ -n "${STAGING_VERSION}" ]; then
        Info "Checking out Wine-Staging version: ${STAGING_VERSION}"
        git fetch --all --tags
        git checkout "${STAGING_VERSION}" || Error "Failed to checkout Wine-Staging version ${STAGING_VERSION}"
    else
        Info "Using latest Wine-Staging version"
        git checkout master
        git pull origin master
    fi

    # Copy sources to build directory
    Info "Preparing build sources..."
    cp -r "${SOURCE_DIR}/wine" "${BUILD_DIR}/wine"
    cp -r "${SOURCE_DIR}/wine-staging" "${BUILD_DIR}/wine-staging-${WINE_VERSION}"

    # Breaks seccomp (example: opening browser from clicking on links in wine)
    if [ "${USE_WOW64}" = "true" ]; then
        Info "WoW64 build: adding staging hotfix to remove the 'ntdll-Syscall_Emulation' patchset"
        STAGING_ARGS+=" -W ntdll-Syscall_Emulation"
    fi

    # Apply patches
    _staging_patcher

    cd "${BUILD_DIR}/wine"

    # Apply custom patches
    mapfile -t patchlist < <(find "${patches_dir}" -type f -regex ".*\.patch" | LC_ALL=C sort -f)
    for patch in "${patchlist[@]}"; do
        [ -f "${patch}" ] || continue
        Info "Applying patch: $(basename "${patch}")"
        patch -Np1 -i "${patch}" >>"${WINE_ROOT}/patches.log" ||
            Error "Failed to apply patch: ${patch}"
    done

    # Initialize git for make_makefiles
    git config commit.gpgsign false
    git config user.email "wine@build.dev"
    git config user.name "winebuild"
    git init
    git add --all
    git commit -m "makepkg"

    # # Generate required files
    # [ -e dlls/winevulkan/make_vulkan ] && {
    #     chmod +x dlls/winevulkan/make_vulkan
    #     dlls/winevulkan/make_vulkan -x vk.xml
    # }

    chmod +x tools/make_requests
    tools/make_requests
    [ -e tools/make_specfiles ] && {
        chmod +x tools/make_specfiles
        tools/make_specfiles
    }

    chmod +x tools/make_makefiles
    tools/make_makefiles
    autoreconf -fiv

    # Build and package
    build_wine
    package_wine

    Info "Build completed successfully!"
}

main "$@"
