#!/usr/bin/env bash

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
export WINE_OSU="false"

# This will make applying low-latency audio osu! patches to Wine possible
# by replacing provided winepulse.drv to Vanilla Wine
# LEAVE IT ON FALSE FOR LATEST WINE-OSU!
export OLD_WINE_OSU="false"

# Use llvm-mingw to compile
export USE_LLVM="false"
export LLVM_MINGW_PATH="/usr/local/llvm-mingw"

## -------------------------------------------------------

# Wine version to compile.
# You can set it to "latest" to compile the latest available version.
#
# This variable affects only vanilla and staging branches. Other branches
# use their own versions.
export WINE_VERSION=""
# Available branches: winello, vanilla, staging, staging-tkg, proton, wayland, custom, local
export WINE_BRANCH="winello"

# Custom path for Wine source
export CUSTOM_WINE_SOURCE=""

# Switch to also package x86-Wine
export BUILD_X86="false"

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

# Sometimes Wine and Staging versions don't match (for example, 5.15.2).
# Leave this empty to use Staging version that matches the Wine version.
export STAGING_VERSION=""

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

export WINE_BUILD_OPTIONS="--disable-tests
	--with-x \
	--with-gstreamer \
	--with-xattr \
	--without-oss \
	--without-coreaudio \
	--without-cups \
	--without-sane"

# Checking for Wayland...
if [ "${ENABLE_WAYLAND}" = "true" ] ; then
	Info "Adding Wayland support.."
	export WINE_BUILD_OPTIONS="${WINE_BUILD_OPTIONS} --with-wayland"
fi

# A temporary directory where the Wine source code will be stored.
# Do not set this variable to an existing non-empty directory!
# This directory is removed and recreated on each script run.
export BUILD_DIR="${HOME}"/build_wine

## ------------------------------------------------------------
## 						BOOTSTRAPS SETUP
## ------------------------------------------------------------

# Change these paths to where your Ubuntu bootstraps reside
export BOOTSTRAP_X64=/opt/chroots/focal64_chroot

export scriptdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

build_with_bwrap () {

	BOOTSTRAP_PATH="${BOOTSTRAP_X64}"

	if [ "${1}" = "64" ]; then
		shift
	fi	

    bwrap --ro-bind "${BOOTSTRAP_PATH}" / --dev /dev --ro-bind /sys /sys \
		  --proc /proc --tmpfs /tmp --tmpfs /home --tmpfs /run --tmpfs /var \
		  --tmpfs /mnt --tmpfs /media --bind "${BUILD_DIR}" "${BUILD_DIR}" \
		  --bind-try "${XDG_CACHE_HOME}"/ccache "${XDG_CACHE_HOME}"/ccache \
		  --bind-try "${HOME}"/.ccache "${HOME}"/.ccache \
		  --setenv PATH "/usr/local/llvm-mingw/bin:/bin:/sbin:/usr/bin:/usr/sbin" \
			"$@"
}

if [ ! -d "${BOOTSTRAP_X64}" ] ; then
	clear
	echo "Ubuntu Bootstrap is required for compilation!"
	exit 1
fi

BWRAP64="build_with_bwrap 64"

## ------------------------------------------------------------

## Setting flags for compilation..
export CC="gcc"
export CXX="g++"

export CROSSCC_X32="i686-w64-mingw32-gcc"
export CROSSCXX_X32="i686-w64-mingw32-g++"
export CROSSCC_X64="x86_64-w64-mingw32-gcc"
export CROSSCXX_X64="x86_64-w64-mingw32-g++"

_CROSS_FLAGS="march=x86-64 -mtune=generic -mfpmath=sse -O2 -ftree-vectorize"
export CFLAGS="-march=x86-64 -mtune=generic -mfpmath=sse -O2 -ftree-vectorize"
export LDFLAGS="-Wl,-O2,--sort-common,--as-needed"
export CROSSLDFLAGS="${LDFLAGS}"
export CROSSCFLAGS="${CFLAGS}"

## ------------------------------------------------------------

## Flags used to compile wine-osu..
if [ "$WINE_OSU" = "true" ]; then
	_GCC_FLAGS="-march=x86-64 -mtune=generic -O3 -pipe -mfpmath=sse -fno-semantic-interposition -fno-strict-aliasing -fomit-frame-pointer -fwrapv -Wno-error=implicit-function-declaration -w -fipa-pta -fgraphite-identity -floop-strip-mine -floop-nest-optimize -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -DNDEBUG -D_NDEBUG"
	_CROSS_FLAGS="-march=x86-64 -mtune=generic -O3 -pipe -mfpmath=sse -fno-semantic-interposition -fno-strict-aliasing -fomit-frame-pointer -fwrapv -Wno-error=implicit-function-declaration -w -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -DNDEBUG -D_NDEBUG"
	export CFLAGS="${_GCC_FLAGS}"
	export CXXFLAGS="${_GCC_FLAGS}"
	export CROSSCFLAGS="${_CROSS_FLAGS}"
	export CROSSCXXFLAGS="${_CROSS_FLAGS}"
	export LD_FLAGS="${_GCC_FLAGS} -Wl,-O2,--sort-common,--as-needed"
	export CROSSLDFLAGS="${_CROSS_FLAGS} -Wl,-O2,--sort-common,--as-needed"
fi

## ------------------------------------------------------------

## Flags used to use LLVM-MINGW for compilation..
if [ "$USE_LLVM" = "true" ]; then
	Info "Using llvm-mingw..."
	export PATH="${LLVM_MINGW_PATH}"/bin:"${PATH}"
	export LD_LIBRARY_PATH="${LLVM_MINGW_PATH}/lib:${LLVM_MINGW_PATH}/x86_64-w64-mingw32/lib:${LLVM_MINGW_PATH}/i686-w64-mingw32/lib:${LLVM_MINGW_PATH}/lib/clang/18/lib/windows:$LD_LIBRARY_PATH"
	export CROSSCC_X32="i686-w64-mingw32-clang"
	export CROSSCC_X64="x86_64-w64-mingw32-clang"
	export CROSSCC="x86_64-w64-mingw32-clang"

	_CROSS_FLAGS="${_CROSS_FLAGS} -L${LLVM_MINGW_PATH}/lib -I${LLVM_MINGW_PATH}/include -I${LLVM_MINGW_PATH}/lib/clang/18/include -I${LLVM_MINGW_PATH}/generic-w64-mingw32/include -L${LLVM_MINGW_PATH}/x86_64-w64-mingw32/lib -L${LLVM_MINGW_PATH}/i686-w64-mingw32/lib -L${LLVM_MINGW_PATH}/lib/clang/18/lib/windows"
	export CROSSCFLAGS="${_CROSS_FLAGS}"
	export CROSSCXXFLAGS="${_CROSS_FLAGS}"
	export CROSSLDFLAGS="${_CROSS_FLAGS} -Wl,-O2,--sort-common,--as-needed"
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

curdir=$(pwd)
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}" || exit 1

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
			Info"CUSTOM_SRC_PATH is set to an incorrect or non-existent directory!"
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

	export WINE_BUILD_OPTIONS="--without-x --without-xcomposite \
                               --without-xfixes --without-xinerama \
                               --without-xinput --without-xinput2 \
                               --without-xrandr --without-xrender \
                               --without-xshape --without-xshm  \
                               --without-xslt --without-xxf86vm \
                               --without-xcursor --without-opengl \
                               ${WINE_BUILD_OPTIONS}"
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
		
		Info "Applying Wine-Staging patches.."

		if [ -f wine-staging-"${WINE_VERSION}"/patches/patchinstall.sh ]; then
			staging_patcher=("${BUILD_DIR}"/wine-staging-"${WINE_VERSION}"/patches/patchinstall.sh
							DESTDIR="${BUILD_DIR}"/wine)
		else
			staging_patcher=("${BUILD_DIR}"/wine-staging-"${WINE_VERSION}"/staging/patchinstall.py)
		fi

		cd wine || exit

		if [ -n "${STAGING_ARGS}" ]; then
			${BWRAP64} "${staging_patcher[@]}" ${STAGING_ARGS}
		else
			${BWRAP64} "${staging_patcher[@]}" --all
		fi

		if [ $? -ne 0 ]; then
			echo
			Info "Wine-Staging patches were not applied correctly!"
			exit 1
		fi
	fi
fi

cd "${BUILD_DIR}" || exit 1

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
		if [ ! -f "$curdir/osu-misc/$file" ]; then
			Error "Some file is missing! Please clone the repo again!"
		fi
	done

	if [ "${OSU_OLD_REVERT}" = "true" ] ; then
		Info "Applying audio reverts.. (old version)"
		rm -rf "${BUILD_DIR}"/wine/dlls/winepulse.drv
		mkdir -p "${BUILD_DIR}"/wine/dlls/winepulse.drv
		tar -xf "$curdir"/osu-misc/old-reverts/winepulse-513.tar -C "${BUILD_DIR}"/wine/dlls/winepulse.drv
	
	else
		Info "Applying audio reverts.."
		rm -rf "${BUILD_DIR}"/wine/dlls/{winepulse.drv,mmdevapi,winealsa.drv,winecoreaudio.drv,wineoss.drv}
		tar -xf "$curdir"/osu-misc/audio-revert.tar -C "${BUILD_DIR}"/wine/dlls/
	fi
	
else
	Info "Replacing Winepulse not needed, skipping.."
fi

# Applying custom patches to Wine
patches_dir=$curdir/custompatches
cd wine
rm $curdir/patches.log

for i in $(find "$patches_dir" -type f -regex ".*\.patch" | sort); do
    [ ! -f "$i" ] && continue
    Info "Applying custom patch '$i'" 
    patch -Np1 -i "$i" >> $curdir/patches.log || Error "Applying patch '$i' failed, read at: $curdir/patches.log"
done

dlls/winevulkan/make_vulkan
tools/make_requests
tools/make_specfiles
${BWRAP64} autoreconf -fiv

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

export PKG_CONFIG_LIBDIR=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:${LLVM_MINGW_PATH}/x86_64-w64-mingw32/lib/pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR
export x86_64_CC="${CROSSCC_X64}"
export CROSSCC="${CROSSCC_X64}"

mkdir "${BUILD_DIR}"/build64
cd "${BUILD_DIR}"/build64
${BWRAP64} "${BUILD_DIR}"/wine/configure \
			--enable-win64 ${WINE_BUILD_OPTIONS} \
			--prefix "${BUILD_DIR}"/wine-${BUILD_NAME}-amd64 \
			--libdir="${BUILD_DIR}"/wine-${BUILD_NAME}-amd64/lib64 \
			--with-mingw="${CROSSCC_X64}"

${BWRAP64} make -j$((`nproc`+1)) || Error "Wine 64-bit build failed, check logs"

export PKG_CONFIG_LIBDIR=/usr/lib/i386-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/i386-linux-gnu/pkgconfig:/usr/local/i386/lib/i386-linux-gnu/pkgconfig:${LLVM_MINGW_PATH}/i686-w64-mingw32/lib/pkgconfig
export LD_LIBRARY_PATH=/usr/local/i386/lib/i386-linux-gnu:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$PKG_CONFIG_LIBDIR
export i386_CC="${CROSSCC_X32}"
export CROSSCC="${CROSSCC_X32}"

mkdir "${BUILD_DIR}"/build32
cd "${BUILD_DIR}"/build32
${BWRAP64} "${BUILD_DIR}"/wine/configure --with-wine64="${BUILD_DIR}"/build64 \
			${WINE_BUILD_OPTIONS} --prefix "${BUILD_DIR}"/wine-${BUILD_NAME}-amd64 \
			--libdir="${BUILD_DIR}"/wine-${BUILD_NAME}-amd64/lib \
			--with-mingw="${CROSSCC_X32}"

${BWRAP64} make -j$((`nproc`+1)) || Error "Wine 32-bit build failed, check logs"

Info "Compilation complete"

cd "${BUILD_DIR}"
export XZ_OPT="-9 -T0"

if [ -d "$BUILD_DIR" ]; then

	Info "Packaging Wine-32..."
	cd "${BUILD_DIR}"/build32
	${BWRAP64} make -j$((`nproc` + 1)) \
	prefix="${BUILD_DIR}"/wine-${BUILD_NAME}-amd64 \
	libdir="${BUILD_DIR}"/wine-${BUILD_NAME}-amd64/lib \
	dlldir="${BUILD_DIR}"/wine-${BUILD_NAME}-amd64/lib/wine install

	Info "Packaging Wine-64..."
	cd "${BUILD_DIR}"/build64
	${BWRAP64} make -j$((`nproc` + 1)) \
	prefix="${BUILD_DIR}"/wine-${BUILD_NAME}-amd64 \
	libdir="${BUILD_DIR}"/wine-${BUILD_NAME}-amd64/lib64 \
	dlldir="${BUILD_DIR}"/wine-${BUILD_NAME}-amd64/lib64/wine install

	for _f in $(find "${BUILD_DIR}"/wine-${BUILD_NAME}-amd64/lib "${BUILD_DIR}"/wine-${BUILD_NAME}-amd64/lib32 "${BUILD_DIR}"/wine-${BUILD_NAME}-amd64/lib64 -type f '(' -iname '*.a' -or -iname '*.dll' -or -iname '*.so' -or -iname '*.sys' -or -iname '*.drv' -or -iname '*.exe' ')'); do
		strip --strip-unneeded "$_f" &>/dev/null && Info "${_f} stripped"
	done

fi

cd "${BUILD_DIR}"
Info "Creating and compressing archives..."
for build in wine-${BUILD_NAME}-amd64; do
	if [ -d "${build}" ]; then
		rm -rf "${build}"/share/applications "${build}"/share/man

		if [ -f wine/wine-tkg-config.txt ]; then
			cp wine/wine-tkg-config.txt "${build}"
		fi

		if [ "${WINE_OSU}" = "true" ] ; then
			
			if [ "${build}" = "wine-${BUILD_NAME}-amd64" ]; then
				
				mv "${build}" "wine-osu"
				tar -Jcf "wine-osu-${WINE_VERSION}-x86_64".tar.xz wine-osu
				mv "wine-osu-${WINE_VERSION}-x86_64".tar.xz "${scriptdir}"

			else

				if [ ${BUILD_X86} == "true" ]; then
					mv "${build}" "wine-osu-x86"
					tar -Jcf "wine-osu-${WINE_VERSION}-x86".tar.xz wine-osu-x86
					mv "wine-osu-${WINE_VERSION}-x86".tar.xz "${scriptdir}"
				fi

			fi
		
		else

		tar -Jcf "${build}".tar.xz "${build}"
		mv "${build}".tar.xz "${scriptdir}"

		fi
	fi
done

rm -rf "${BUILD_DIR}"

#clear
Info "Done! Build completed!"
