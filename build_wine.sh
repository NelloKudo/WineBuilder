#!/usr/bin/env bash

scriptdir="${PWD:-$(pwd)}"

########################################################################
##
## A script for Wine compilation, forked from https://github.com/Kron4ek/Wine-Builds
## to make applying patches easier. Thanks to Kron4ek and other contributors for the amazing work <3
##
## By default it uses two Ubuntu bootstraps (x32 and x64), which it enters
## with bubblewrap (root rights are not required).
##
## This script requires: git, wget, autoconf, xz, bubblewrap, bc
##
## You can change the environment variables below to your desired values.
##
########################################################################

Info()
{
	echo -e '\033[1;34m'"WineBuilder:\033[0m $*";
}


Error()
{
    echo -e '\033[1;31m'"WineBuilder:\033[0m $*"; exit 1;
}

# Prevent launching as root
if [ $EUID = 0 ] && [ -z "$ALLOW_ROOT" ]; then
	Info "Do not run this script as root!"
	echo
	Info "If you really need to run it as root and you know what you are doing,"
	Info "set the ALLOW_ROOT environment variable."

	exit 1
fi

## -------------------------------------------------------
##				WineBuilder osu! Settings
## -------------------------------------------------------

# This will enable compilation flags optimized for latest
# wine-osu builds!
export WINE_OSU="true"

# This will make applying low-latency audio osu! patches to Wine possible
# by replacing provided winepulse.drv to Vanilla Wine
# LEAVE IT ON FALSE FOR LATEST WINE-OSU!
export OLD_WINE_OSU="false"

# Use llvm-mingw to compile (default since 9.11)
export USE_LLVM="true"

# Use clang instead of gcc (default since 9.11-2, requires USE_LLVM=true)
export USE_CLANG="true"

## -------------------------------------------------------


# A temporary directory where the Wine source code will be stored.
# Do not set this variable to an existing non-empty directory!
# This directory is removed and recreated on each script run.

BUILD_DIR="${scriptdir}"/build_wine

# Setting this to true will build wine in /tmp/
# and then move it over to your specified build directory, for sanitized names.
# Otherwise, it just builds inside of BUILD_DIR.
SANITIZED_BUILD="true"

# Wine version to compile.
# You can set it to "latest" to compile the latest available version. (not for winello)
#
# This variable affects only winello-git, vanilla, and staging branches. Other branches
# use their own versions.
# "winello-git" takes tag names or commit hashes (e.g. wine-9.11)
export WINE_VERSION="wine-9.14"
# This only applies to winello-git branches. Takes tag names or commit hashes (e.g. v9.11)
export STAGING_VERSION="v9.14"

# Available branches: winello-git, winello, vanilla, staging, staging-tkg, proton, wayland, custom, local
export WINE_BRANCH="winello-git"

# Optional extra release identifier to be added to the package, otherwise will be 1
export RELEASE_VERSION="2"

# Name for patchset you want to apply (e.g. protonGE-9-4-osu-patchset from osu-misc/patches/)
# Leave empty if you have loose patches in custompatches/
PATCHSET="9.14-patchset"
# Custom path for Wine source
export CUSTOM_WINE_SOURCE=""

# Switch to use old revert method for wine-osu (ex. Wine 8.0 or previous)
# This only reverts winepulse.drv!!
export OSU_OLD_REVERT="false"

# Adds Wayland support to Wine builds. Should work by default on latest builds, 
# probably needs to be set on false on custom/older ones.
export ENABLE_WAYLAND="true"

# Available proton branches: proton_3.7, proton_3.16, proton_4.2, proton_4.11
# proton_5.0, proton_5.13, experimental_5.13, proton_6.3, experimental_6.3
# proton_7.0, experimental_7.0
# Leave empty to use the default branch.
export PROTON_BRANCH="proton_7.0"

# Specify custom arguments for the Staging's patchinstall.sh script.
# For example, if you want to disable ntdll-NtAlertThreadByThreadId
# patchset, but apply all other patches, then set this variable to
# "--all -W ntdll-NtAlertThreadByThreadId"
# Leave empty to apply all Staging patches
export STAGING_ARGS="--all"

# Set this to a path to your Wine source code (for example, /home/username/wine-custom-src).
# This is useful if you already have the Wine source code somewhere on your
# storage and you want to compile it.
#
# You can also set this to a GitHub clone url instead of a local path.
#
# If you don't want to compile a custom Wine source code, then just leave this
# variable empty.
export CUSTOM_SRC_PATH=""

# Set to true to download and prepare the source code, but do not compile it.
# If this variable is set to true, root rights are not required.
export DO_NOT_COMPILE="false"

# Set to true to use ccache to speed up subsequent compilations.
# First compilation will be a little longer, but subsequent compilations
# will be significantly faster (especially if you use a fast storage like SSD).
#
# Note that ccache requires additional storage space.
# By default it has a 5 GB limit for its cache size.
#
# Make sure that ccache is installed before enabling this.
export USE_CCACHE="true"

## ------------------------------------------------------------
## 						BUILD SETUP
## ------------------------------------------------------------

BUILD_OUT_TMP_DIR=wine-"${WINE_BRANCH}"-build

if [ "${SANITIZED_BUILD}" = "true" ]; then
	Info "Using experimental sanitized build."

	_SANITIZED_BUILD_DIR=$(basename "${BUILD_DIR}")
	old_BUILD_DIR="${BUILD_DIR}"
	BUILD_DIR="/tmp/${_SANITIZED_BUILD_DIR}"

	mkdir -p "${BUILD_DIR}" || Error "Error setting up sanitized build directory. Do you not have a /tmp/ directory for some reason?"
fi

WINE_BUILD_OPTIONS=(
	--prefix="${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}"
	--disable-tests
	--with-x
	--with-gstreamer
	--with-xattr
	--without-oss
	--without-coreaudio
	--without-cups
	--without-sane
)

# Options appended only to the lib64 portion of the build
WINE_64_BUILD_OPTIONS=(
	--enable-win64
	--libdir="${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}"/lib64
)

# Options appended only to the lib32 portion of the build
WINE_32_BUILD_OPTIONS=(
	--libdir="${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}"/lib
    --with-wine64="${BUILD_DIR}"/build64
)

# Checking for Wayland...
if [ "${ENABLE_WAYLAND}" = "true" ] ; then
	Info "Adding Wayland support.."
	WINE_BUILD_OPTIONS+=(--with-wayland)
fi

## ------------------------------------------------------------
## 						BOOTSTRAPS SETUP
## ------------------------------------------------------------

# Change these paths to where your Ubuntu bootstraps reside
_distro=$(grep "${scriptdir}"/create_ubuntu_bootstraps.sh -e "CHROOT_DISTRO=" | cut -f2 -d'"')
export BOOTSTRAP_PATH=/opt/chroots/"${_distro}"_chroot

# Alias for bwrap setup
_bwrap () {
    bwrap --ro-bind "${BOOTSTRAP_PATH}" / --dev /dev --ro-bind /sys /sys \
		  --proc /proc --tmpfs /tmp --tmpfs /home --tmpfs /run --tmpfs /var \
		  --tmpfs /mnt --tmpfs /media --bind "${BUILD_DIR}" "${BUILD_DIR}" \
		  --bind-try "${XDG_CACHE_HOME}"/ccache "${XDG_CACHE_HOME}"/ccache \
		  --bind-try "${HOME}"/.ccache "${HOME}"/.ccache \
		  --setenv PATH "/usr/local/llvm-mingw/bin:/bin:/sbin:/usr/bin:/usr/sbin" \
		  --setenv LC_ALL en_US.UTF-8 \
		  --setenv LANGUAGE en_US.UTF-8 \
		  "$@"
			
}

if [ ! -d "${BOOTSTRAP_PATH}" ] ; then
	clear
	echo "Ubuntu Bootstrap is required for compilation!"
	exit 1
fi

## ------------------------------------------------------------

## Setting flags for compilation..
export LLVM_MINGW_PATH="/usr/local/llvm-mingw"

export CC="gcc"
export CXX="g++"

export CROSSCC_X32="i686-w64-mingw32-gcc"
export CROSSCXX_X32="i686-w64-mingw32-g++"
export CROSSCC_X64="x86_64-w64-mingw32-gcc"
export CROSSCXX_X64="x86_64-w64-mingw32-g++"

export CFLAGS="-march=x86-64 -mtune=generic -O2 -ftree-vectorize"
export CROSSCFLAGS="-march=x86-64 -mtune=generic -O2 -ftree-vectorize"
export LDFLAGS="-Wl,-O2,--sort-common,--as-needed"
export CROSSLDFLAGS="${LDFLAGS}"

## ------------------------------------------------------------

## Flags used to compile wine-osu..
if [ "$WINE_OSU" = "true" ]; then
	export CPPFLAGS="-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -DNDEBUG -D_NDEBUG"
	_common_cflags="-march=x86-64 -mtune=generic -O2 -pipe -fno-strict-aliasing -fomit-frame-pointer -fwrapv -Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration -Wno-error=int-conversion -w"
	_native_common_cflags="" # only for the non-mingw side

	_GCC_FLAGS="${_common_cflags} ${_native_common_cflags} ${CPPFLAGS}"
	_LD_FLAGS="${_GCC_FLAGS} -Wl,-O2,--sort-common,--as-needed"

	_CROSS_FLAGS="${_common_cflags} ${CPPFLAGS}"
	_CROSS_LD_FLAGS="${_CROSS_FLAGS} -Wl,-O2,--sort-common,--as-needed,--file-alignment=4096"

	export CFLAGS="${_GCC_FLAGS}"
	export CXXFLAGS="${_GCC_FLAGS}"
	export LDFLAGS="${_LD_FLAGS}"

	export CROSSCFLAGS="${_CROSS_FLAGS}"
	export CROSSCXXFLAGS="${_CROSS_FLAGS}"
	export CROSSLDFLAGS="${_CROSS_LD_FLAGS}"
fi

## ------------------------------------------------------------

## Flags used to use LLVM-MinGW/clang for compilation..
if [ "$USE_LLVM" = "true" ] && [ "$WINE_OSU" = "true" ]; then
	Info "Using llvm-mingw for cross-CC..."
	export PATH="${LLVM_MINGW_PATH}"/bin:"${PATH}"
	export CROSSCC_X32="i686-w64-mingw32-clang"
	export CROSSCC_X64="x86_64-w64-mingw32-clang"
	export CROSSCC="x86_64-w64-mingw32-clang"

	# feel free to do this a better way :)
	__llvm_ver="$(basename "$(find "${BOOTSTRAP_PATH}"/"${LLVM_MINGW_PATH}"/lib/clang/ -mindepth 1 -maxdepth 1)" )" || \
		Error "llvm-mingw didn't have a valid version in lib/clang/_version_"

	_CROSS_FLAGS="${_CROSS_FLAGS} -L${LLVM_MINGW_PATH}/lib -I${LLVM_MINGW_PATH}/include -I${LLVM_MINGW_PATH}/lib/clang/$__llvm_ver/include -I${LLVM_MINGW_PATH}/generic-w64-mingw32/include -L${LLVM_MINGW_PATH}/x86_64-w64-mingw32/lib -L${LLVM_MINGW_PATH}/i686-w64-mingw32/lib -L${LLVM_MINGW_PATH}/lib/clang/$__llvm_ver/lib/windows"
	export CROSSCFLAGS="${_CROSS_FLAGS}"
	export CROSSCXXFLAGS="${_CROSS_FLAGS}"

	WINE_64_BUILD_OPTIONS+=(--with-mingw="$CROSSCC_X64")
	WINE_32_BUILD_OPTIONS+=(--with-mingw="$CROSSCC_X32")

	if [ "$USE_CLANG" = "true" ]; then
		Info "Using clang for CC..."
		export CC="clang"
		export CXX="clang++"
	fi
fi

## ------------------------------------------------------------

## Flags changes in order to use ccache..
if [ "$USE_CCACHE" = "true" ]; then
	export CC="ccache ${CC}"
	export CXX="ccache ${CXX}"

	export i386_CC="ccache ${CROSSCC_X32}"
	export x86_64_CC="ccache ${CROSSCC_X64}"

	export CROSSCC="ccache ${CROSSCC}"
	export CROSSCC_X32="ccache ${CROSSCC_X32}"
	export CROSSCXX_X32="ccache ${CROSSCXX_X32}"
	export CROSSCC_X64="ccache ${CROSSCC_X64}"
	export CROSSCXX_X64="ccache ${CROSSCXX_X64}"

	if [ -z "${XDG_CACHE_HOME}" ]; then
		export XDG_CACHE_HOME="${HOME}"/.cache
	fi

	mkdir -p "${XDG_CACHE_HOME}"/ccache
	mkdir -p "${HOME}"/.ccache
fi

## ------------------------------------------------------------

## Helper function to apply staging patches
_staging_patcher() {
	Info "Applying Wine-Staging patches.."

	if [ -f wine-staging-"${WINE_VERSION}"/patches/patchinstall.sh ]; then
		staging_patcher=("${BUILD_DIR}"/wine-staging-"${WINE_VERSION}"/patches/patchinstall.sh
						DESTDIR="${BUILD_DIR}"/wine)
	else
		staging_patcher=("${BUILD_DIR}"/wine-staging-"${WINE_VERSION}"/staging/patchinstall.py)
	fi

	cd wine || Error "Couldn't change directory to wine's source folder"

	if [ -n "${STAGING_ARGS}" ]; then
		_bwrap "${staging_patcher[@]}" $STAGING_ARGS
	else
		_bwrap "${staging_patcher[@]}" --all
	fi || Error "Wine-Staging patches were not applied correctly!"

}

## ------------------------------------------------------------

# Replace the "latest" parameter with the actual latest Wine version
if [ "${WINE_VERSION}" = "latest" ] || [ -z "${WINE_VERSION}" ]; then
	WINE_VERSION="$(wget -q -O - "https://raw.githubusercontent.com/wine-mirror/wine/master/VERSION" | tail -c +14)"
fi

# Stable and Development versions have a different source code location
# Determine if the chosen version is stable or development
if [ "$(echo "$WINE_VERSION" | cut -c3)" = "0" ]; then
	WINE_URL_VERSION=$(echo "$WINE_VERSION" | cut -c1).0
else
	WINE_URL_VERSION=$(echo "$WINE_VERSION" | cut -c1).x
fi

if ! [ "$WINE_BRANCH" = "winello-git" ]; then
	rm -rf "${BUILD_DIR}" || true
fi

mkdir -p "${BUILD_DIR}" || Error "Couldn't create ${BUILD_DIR}?"
cd "${BUILD_DIR}" || Error "Couldn't cd to ${BUILD_DIR}?"

echo
Info "Downloading the source code and patches"
Info "Preparing Wine for compilation"
echo

if [ -n "${CUSTOM_SRC_PATH}" ]; then
	is_url="$(echo "${CUSTOM_SRC_PATH}" | head -c 6)"

	if [ "${is_url}" = "git://" ] || [ "${is_url}" = "https:" ]; then
		git clone "${CUSTOM_SRC_PATH}" wine
	else
		if [ ! -f "${CUSTOM_SRC_PATH}"/configure ]; then
			Info "CUSTOM_SRC_PATH is set to an incorrect or non-existent directory!"
			Info "Please make sure to use a directory with the correct Wine source code."
			exit 1
		fi

		cp -r "${CUSTOM_SRC_PATH}" wine
	fi

	WINE_VERSION="$(cat wine/VERSION | tail -c +14)"
	BUILD_NAME="${WINE_VERSION}"-custom
elif [ "$WINE_BRANCH" = "staging-tkg" ]; then
	git clone https://github.com/Kron4ek/wine-tkg wine

	WINE_VERSION="$(cat wine/VERSION | tail -c +14)"
	BUILD_NAME="${WINE_VERSION}"-staging-tkg
elif [ "$WINE_BRANCH" = "wayland" ]; then
	git clone https://github.com/Kron4ek/wine-wayland wine

	WINE_VERSION="$(cat wine/VERSION | tail -c +14)"
	BUILD_NAME="${WINE_VERSION}"-wayland

	WINE_BUILD_OPTIONS+=(--without-x --without-xcomposite
                               --without-xfixes --without-xinerama
                               --without-xinput --without-xinput2
                               --without-xrandr --without-xrender
                               --without-xshape --without-xshm
                               --without-xslt --without-xxf86vm
                               --without-xcursor --without-opengl
	)
elif [ "$WINE_BRANCH" = "proton" ]; then
	if [ -z "${PROTON_BRANCH}" ]; then
		git clone https://github.com/ValveSoftware/wine
	else
		git clone https://github.com/ValveSoftware/wine -b "${PROTON_BRANCH}"
	fi

	WINE_VERSION="$(cat wine/VERSION | tail -c +14)"
	BUILD_NAME="${WINE_VERSION}"-proton
elif [ "$WINE_BRANCH" = "custom" ]; then
	if  [ ! -z "$CUSTOM_WINE_SOURCE" ]; then
		git clone "$CUSTOM_WINE_SOURCE" wine || Error "Cloning failed, is the source you used working? Please try again."

		WINE_VERSION="$(cat wine/VERSION | tail -c +14)"
		BUILD_NAME="${WINE_VERSION}"-custom
	else
		Error "Please add a Wine source to CUSTOM_WINE_SOURCE."
	fi
elif [ "$WINE_BRANCH" = "winello" ]; then
	git clone https://github.com/NelloKudo/winello-wine.git wine || Error "Cloning failed, is the source you used working? Please try again."

	WINE_VERSION="$(cat wine/VERSION | tail -c +14)"
	BUILD_NAME="${WINE_VERSION}"-winello
elif [ "$WINE_BRANCH" = "local" ]; then
	echo ""
	## Time for your local tests! Example, try your own source like this:
	# cp -r /your/local/wine "${BUILD_DIR}"/wine
elif [ "$WINE_BRANCH" = "winello-git" ]; then
	# Wine setup
	if [ -d "${BUILD_DIR}"/wine ]; then
		cd "${BUILD_DIR}"/wine
		git fetch origin master
		git reset --hard FETCH_HEAD
		git clean -xdf
	else
		git clone https://github.com/wine-mirror/wine || Error "Cloning wine failed, is the source you used working? Please try again."
	fi || Error "Setting up wine-staging git source failed. Clean out your build directory and try again."
	
	cd "${BUILD_DIR}"/wine

	if [ -n "${WINE_VERSION}" ]; then
		Info "Setting wine commit to ${WINE_VERSION}, was at $(git rev-parse HEAD)"
		git reset --hard "${WINE_VERSION}" || Error "Failed to change to your selected WINE_VERSION."
	fi

	if [ "$(git rev-parse HEAD)" = "09a6d0f2913b064e09ed0bdc27b7bbc17a5fb0fc" ]; then
		Info "Adding staging hotfix to remove the 'odbc-remove-unixodbc' patchset"
		STAGING_ARGS+=" -W odbc-remove-unixodbc"
	fi

	WINE_VERSION=$(git describe --tags --abbrev=0 | cut -f2 -d'-')
	BUILD_NAME=winello-git

	cd "${BUILD_DIR}"

	# Staging setup
	if [ -d wine-staging-"${WINE_VERSION}" ]; then
		cd wine-staging-"${WINE_VERSION}"
		git fetch origin master
		git reset --hard FETCH_HEAD
		git clean -xdf
	else
		git clone https://github.com/wine-staging/wine-staging wine-staging-"${WINE_VERSION}" || Error "Cloning wine-staging failed, is the source you used working? Please try again."
	fi || Error "Setting up wine-staging git source failed. Clean out your build directory and try again."

	cd "${BUILD_DIR}"/wine-staging-"${WINE_VERSION}"

	if [ -n "${STAGING_VERSION}" ]; then
		Info "Setting wine-staging commit to ${STAGING_VERSION}, was at $(git rev-parse HEAD)"
		git reset --hard "${STAGING_VERSION}" || Error "Failed to change to your selected STAGING_VERSION."
	fi

	cd "${BUILD_DIR}"

	_staging_patcher
else
	BUILD_NAME="${WINE_VERSION}"

	wget -q --show-progress "https://dl.winehq.org/wine/source/${WINE_URL_VERSION}/wine-${WINE_VERSION}.tar.xz"

	tar xf "wine-${WINE_VERSION}.tar.xz"
	mv "wine-${WINE_VERSION}" wine

	if [ "${WINE_BRANCH}" = "staging" ]; then
		if [ -n "$STAGING_VERSION" ]; then
			WINE_VERSION="${STAGING_VERSION}"
		fi

		BUILD_NAME="${WINE_VERSION}"-staging

		wget -q --show-progress "https://github.com/wine-staging/wine-staging/archive/v${WINE_VERSION}.tar.gz"
		tar xf v"${WINE_VERSION}".tar.gz

		if [ ! -f v"${WINE_VERSION}".tar.gz ]; then
			git clone https://github.com/wine-staging/wine-staging wine-staging-"${WINE_VERSION}"
		fi
		
		echo

		_staging_patcher
	fi
fi

cd "${BUILD_DIR}" || Error "Couldn't change directory to build dir?"

if [ ! -d wine ]; then
	clear
	echo "No Wine source code found!"
	Info "Make sure that the correct Wine version is specified."
	exit 1
fi

# Changing winepulse.drv and other audio components for osu! if enabled
if [ "${OLD_WINE_OSU}" = "true" ] ; then

	osu_files=("audio-revert.tar")

	for file in "${osu_files[@]}"
	do
		if [ ! -f "$scriptdir/osu-misc/$file" ]; then
			Error "Some file is missing! Please clone the repo again!"
		fi
	done

	if [ "${OSU_OLD_REVERT}" = "true" ] ; then
		Info "Applying audio reverts.. (old version)"
		rm -rf "${BUILD_DIR}"/wine/dlls/winepulse.drv
		mkdir -p "${BUILD_DIR}"/wine/dlls/winepulse.drv
		tar -xf "$scriptdir"/osu-misc/old-reverts/winepulse-513.tar -C "${BUILD_DIR}"/wine/dlls/winepulse.drv
	
	else
		Info "Applying audio reverts.."
		rm -rf "${BUILD_DIR}"/wine/dlls/{winepulse.drv,mmdevapi,winealsa.drv,winecoreaudio.drv,wineoss.drv}
		tar -xf "$scriptdir"/osu-misc/audio-revert.tar -C "${BUILD_DIR}"/wine/dlls/
	fi
	
else
	Info "Replacing Winepulse not needed, skipping.."
fi

## ------------------------------------------------------------

# Applying custom patches to Wine
patches_dir="${scriptdir}"/custompatches
if [ -n "${PATCHSET}" ]; then
	rm -rf "${scriptdir}"/patchset-current || true
	mkdir "${scriptdir}"/patchset-current
	tar xf "$(find "${scriptdir}"/osu-misc/ -type f -iregex ".*${PATCHSET}.*")" -C "${scriptdir}"/patchset-current || Error "The patchset you specified was invalid."

	patches_dir="${scriptdir}"/patchset-current
fi

cd "${BUILD_DIR}"/wine
rm "${scriptdir}"/patches.log || true

for i in $(find "$patches_dir" -type f -iregex ".*\.patch"  | LC_ALL=C sort -f ); do
    Info "Applying custom patch '$i'"
    patch -Np1 -i "$i" >> "${scriptdir}"/patches.log || Error "Applying patch '$i' failed, read at: ${scriptdir}/patches.log"
done

# for make_makefiles
git config user.email "wine@build.dev" &> /dev/null || true
git config user.name "winebuild" &> /dev/null || true
git init &> /dev/null || true
git add --all || true
git commit -m "makepkg" || true

chmod +x tools/make_makefiles
tools/make_makefiles
chmod +x tools/make_requests
tools/make_requests
if [ -e tools/make_specfiles ]; then
chmod +x tools/make_specfiles
tools/make_specfiles
fi
_bwrap autoreconf -fiv

cd "${BUILD_DIR}"

if [ "${DO_NOT_COMPILE}" = "true" ]; then
	clear
	echo "DO_NOT_COMPILE is set to true"
	echo "Force exiting"
	exit
fi

if ! command -v bwrap 1>/dev/null; then
	echo "Bubblewrap is not installed on your system!"
	echo "Please install it and run the script again"
	exit 1
fi

# Setup reproducible build and ensure ccache works
export SOURCE_DATE_EPOCH=0

export PKG_CONFIG_LIBDIR=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:${LLVM_MINGW_PATH}/x86_64-w64-mingw32/lib/pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR
export x86_64_CC="${CROSSCC_X64}"
export CROSSCC="${CROSSCC_X64}"

rm -rf "${BUILD_DIR}"/build64 || true
mkdir "${BUILD_DIR}"/build64
cd "${BUILD_DIR}"/build64
_bwrap "${BUILD_DIR}"/wine/configure \
			"${WINE_BUILD_OPTIONS[@]}" \
			"${WINE_64_BUILD_OPTIONS[@]}"

_bwrap make -j$(($(nproc) + 1)) || Error "Wine 64-bit build failed, check logs"

export PKG_CONFIG_LIBDIR=/usr/lib/i386-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/i386-linux-gnu/pkgconfig:/usr/local/i386/lib/i386-linux-gnu/pkgconfig:${LLVM_MINGW_PATH}/i686-w64-mingw32/lib/pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR
export i386_CC="${CROSSCC_X32}"
export CROSSCC="${CROSSCC_X32}"

if [ "$USE_CLANG" = "true" ]; then
	# fsync doesn't compile (ntdll.so) on i386 due to undefined atomic ops otherwise
	export I386_LIBS="-latomic"
fi

rm -rf "${BUILD_DIR}"/build32 || true
mkdir "${BUILD_DIR}"/build32
cd "${BUILD_DIR}"/build32
_bwrap "${BUILD_DIR}"/wine/configure \
			"${WINE_BUILD_OPTIONS[@]}" \
			"${WINE_32_BUILD_OPTIONS[@]}"

_bwrap make -j$(($(nproc) + 1)) || Error "Wine 32-bit build failed, check logs"

unset SOURCE_DATE_EPOCH

Info "Compilation complete"

cd "${BUILD_DIR}"
export XZ_OPT="-9 -T0 "

if [ -d "$BUILD_DIR" ]; then

	Info "Packaging Wine-32..."
	cd "${BUILD_DIR}"/build32
	_bwrap make -j$(($(nproc) + 1)) \
	prefix="${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}" \
	libdir="${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}"/lib \
	dlldir="${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}"/lib/wine install

	Info "Packaging Wine-64..."
	cd "${BUILD_DIR}"/build64
	# clang doesn't like to build static lib64
	_bwrap make -j$(($(nproc) + 1)) "$( if [ "$USE_CLANG" = "true" ]; then echo CC=gcc ; fi )" \
	prefix="${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}" \
	libdir="${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}"/lib64 \
	dlldir="${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}"/lib64/wine install

	Info "Stripping unneeded symbols from libraries..."
    find "${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}"/lib{,64} \
      -type f '(' -iname '*.a' -or -iname '*.dll' -or -iname '*.so' -or -iname '*.sys' -or -iname '*.drv' -or -iname '*.exe' ')' \
      -print0 \
      | xargs -0 strip --strip-unneeded &>/dev/null || true

fi

if [ "${SANITIZED_BUILD}" = "true" ]; then
	Info "Moving sanitized build to your specified location."
	rm -rf "${old_BUILD_DIR}" || true
	mkdir "${old_BUILD_DIR}" || Error "Couldn't make a directory where you wanted to."
	mv "${BUILD_DIR}"/"${BUILD_OUT_TMP_DIR}" "${old_BUILD_DIR}"/ || Error "Couldn't copy the sanitized build to your final build location."
	rm -rf "${BUILD_DIR}"/build{32,64} || true

	BUILD_DIR="${old_BUILD_DIR}"
fi

cd "${BUILD_DIR}"
Info "Creating and compressing archives..."

build="${BUILD_OUT_TMP_DIR}"
if [ -d "${build}" ]; then
	rm -rf "${build}"/share/applications "${build}"/share/man

	if [ -f wine/wine-tkg-config.txt ]; then
		cp wine/wine-tkg-config.txt "${build}"
	fi

	if [ "${WINE_OSU}" = "true" ] ; then
		if [ -z "${RELEASE_VERSION}" ]; then RELEASE_VERSION="1" ; fi

		rm -rf "wine-osu" || true # remove old wine-osu dir if existing
		mv "${build}" "wine-osu"
		rm -rf "${build}" || true # remove temp dir

		tar -Jcf "wine-osu-${BUILD_NAME}-${WINE_VERSION}-${RELEASE_VERSION}-x86_64".tar.xz  --numeric-owner --owner=0 --group=0 --null  wine-osu
		mv "wine-osu-${BUILD_NAME}-${WINE_VERSION}-${RELEASE_VERSION}-x86_64".tar.xz "${scriptdir}"

	else

		tar -Jcf "${build}".tar.xz "${build}"
		mv "${build}".tar.xz "${scriptdir}"

	fi
	if [ "${SANITIZED_BUILD}" = "true" ]; then
		Info "Sanitized build: Removing uncompressed local build directory."
		rm -rf "${BUILD_DIR}"
	fi
fi

# we should keep the git sources around since they take up quite a bit of space, just delete the temp build dirs
if ! [ "${WINE_BRANCH}" = "winello-git" ]; then 
	rm -rf "${BUILD_DIR}"
else
	rm -rf "${BUILD_DIR}"/build{32,64}
fi

Info "Done! Build completed!"
