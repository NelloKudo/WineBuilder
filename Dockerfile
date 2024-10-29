FROM ubuntu:focal AS main-deps

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/usr/local/llvm-mingw/bin:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin" \
    MIRROR="http://archive.ubuntu.com/ubuntu/" \
    LIBXKBCOMMON_VERSION="1.7.0" \
    LLVM_MINGW_VERSION="20241015" \
    XZ_VERSION="5.6.3" \
    LIBUNWIND_VERSION="1.8.1"

RUN set -eux; \
    echo "deb $MIRROR focal main restricted" > /etc/apt/sources.list && \
    echo "deb $MIRROR focal-updates main restricted" >> /etc/apt/sources.list && \
    echo "deb $MIRROR focal universe" >> /etc/apt/sources.list && \
    echo "deb $MIRROR focal-updates universe" >> /etc/apt/sources.list && \
    echo "deb $MIRROR focal multiverse" >> /etc/apt/sources.list && \
    echo "deb $MIRROR focal-updates multiverse" >> /etc/apt/sources.list && \
    echo "deb $MIRROR focal-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu focal-security main restricted" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu focal-security universe" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu focal-security multiverse" >> /etc/apt/sources.list && \
    echo "deb-src $MIRROR focal main restricted" >> /etc/apt/sources.list && \
    echo "deb-src $MIRROR focal-updates main restricted" >> /etc/apt/sources.list && \
    echo "deb-src $MIRROR focal universe" >> /etc/apt/sources.list && \
    echo "deb-src $MIRROR focal-updates universe" >> /etc/apt/sources.list && \
    echo "deb-src $MIRROR focal multiverse" >> /etc/apt/sources.list && \
    echo "deb-src $MIRROR focal-updates multiverse" >> /etc/apt/sources.list && \
    echo "deb-src $MIRROR focal-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src http://security.ubuntu.com/ubuntu focal-security main restricted" >> /etc/apt/sources.list && \
    echo "deb-src http://security.ubuntu.com/ubuntu focal-security universe" >> /etc/apt/sources.list && \
    echo "deb-src http://security.ubuntu.com/ubuntu focal-security multiverse" >> /etc/apt/sources.list

RUN dpkg --add-architecture i386 && apt-get update && apt-get -y install \
    git curl locales debhelper python3 python3-apt software-properties-common \
    gpg python3-distutils python3-setuptools python3-pip python3-fonttools \
    python3-ldb python3-talloc wget ca-certificates && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys 1E9377A2BA9EF27F && \
    gpg --export --armor 1E9377A2BA9EF27F | apt-key add - && \
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    pip3 install --upgrade pip && \
    pip3 install meson ninja

RUN apt-get update && apt-get -y install \
    jq        libxt-dev    libxslt1-dev    gcc-13-multilib  libudev-dev:i386    libxcursor-dev:i386 \
    flex      mingw-w64    unixodbc-dev    libavdevice-dev  libcupsimage2-dev   libavcodec-dev:i386 \
    gawk      libcolord2   libcups2-dev    libegl-dev:i386  libgles2-mesa-dev   libsystemd-dev:i386 \
    nano      libegl-dev   libglu1-mesa    libgcrypt20-dev  libglu1-mesa:i386   libavdevice-dev:i386 \
    nasm      libgif-dev   docbook-utils   libgl1-mesa-dev  libglvnd-dev:i386   libgl1-mesa-dev:i386 \
    bison     libglx-dev   glslang-tools   libglx-dev:i386  liblcms2-dev:i386   libgnutls28-dev:i386 \
    cargo     libosmesa6   libavutil-dev   libgnutls28-dev  libpulse-dev:i386   libibus-1.0-dev:i386 \
    meson     libpng-dev   libcapi20-dev   libibus-1.0-dev  libswresample-dev   libxinerama-dev:i386 \
    rustc     libssl-dev   libdbus-1-dev   libosmesa6:i386  libvkd3d-dev:i386   mesa-common-dev:i386 \
    ccache    libv4l-dev   libmpg123-dev   libv4l-dev:i386  libxcomposite-dev   libegl1-mesa-dev:i386 \
    g++-13    libvulkan1   libopenal-dev   libvulkan1:i386  libxslt1-dev:i386   libfreetype6-dev:i386 \
    gcc-13    samba-libs   libunwind-dev   libxinerama-dev  wayland-protocols   libglu1-mesa-dev:i386 \
    libgl1    libacl1-dev  libvulkan-dev   mesa-common-dev  desktop-file-utils  libunistring-dev:i386 \
    gettext   libgl1:i386  libxrandr-dev   build-essential  libavutil-dev:i386  libusb-1.0-0-dev:i386 \
    libglx0   libgles-dev  libasound2-dev  libunistring-dev libcapi20-dev:i386  libcupsimage2-dev:i386 \
    prelink   libgsm1-dev  libavcodec-dev  libusb-1.0-0-dev libdbus-1-dev:i386  libgles2-mesa-dev:i386 \
    jadetex   libkrb5-dev  libgl-dev:i386  libxml2-dev:i386 libfontconfig1-dev  libswresample-dev:i386 \
    autoconf  libldap-dev  libgphoto2-dev  xserver-xorg-dev libmpg123-dev:i386  libxcomposite-dev:i386 \
    libppl14  libpcap-dev  libllvm12:i386  libegl1-mesa-dev libopenal-dev:i386  libfontconfig1-dev:i386 \
    oss4-dev  libsane-dev  libncurses-dev  libfreetype6-dev libunwind-dev:i386  ocl-icd-opencl-dev:i386 \
    valgrind  libsdl2-dev  libosmesa6-dev  libgpg-error-dev libvulkan-dev:i386  libgstreamer1.0-dev:i386 \
    samba-dev libtiff-dev  libswscale-dev  libgles-dev:i386 libxrandr-dev:i386  libwayland-egl-backend-dev \
    schedtool libudev-dev  libwayland-dev  libglu1-mesa-dev ocl-icd-opencl-dev  libwayland-egl-backend-dev:i386 \
    sharutils libxml2-dev  libxcb-xkb-dev  libgsm1-dev:i386 libgphoto2-dev:i386 libgstreamer-plugins-base1.0-dev \
    fontforge libglvnd-dev libxcursor-dev  libldap-dev:i386 libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev:i386 \
    fonttools libglx0:i386 libxi-dev:i386  libpcap-dev:i386 libncurses-dev:i386 \
    libgl-dev liblcms2-dev linux-libc-dev  libsane-dev:i386 libosmesa6-dev:i386 \
    libllvm12 libpulse-dev libsystemd-dev  libsdl2-dev:i386 libswscale-dev:i386 \
    libxi-dev libvkd3d-dev g++-13-multilib libtiff-dev:i386 libxcb-xkb-dev:i386

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 90 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-13 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-13

FROM main-deps AS manual-deps

RUN wget -O llvm-mingw-${LLVM_MINGW_VERSION}.tar.xz \
    https://github.com/mstorsjo/llvm-mingw/releases/download/${LLVM_MINGW_VERSION}/llvm-mingw-${LLVM_MINGW_VERSION}-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    tar -xf llvm-mingw-${LLVM_MINGW_VERSION}.tar.xz -C /usr/local && \
    rm -rf /usr/local/llvm-mingw && \
    mv /usr/local/llvm-mingw-${LLVM_MINGW_VERSION}-ucrt-ubuntu-20.04-x86_64 /usr/local/llvm-mingw

WORKDIR /build

RUN wget -O libxkbcommon.tar.xz https://xkbcommon.org/download/libxkbcommon-${LIBXKBCOMMON_VERSION}.tar.xz && \
    tar -xf libxkbcommon.tar.xz && \
    cd libxkbcommon-${LIBXKBCOMMON_VERSION} && \
    # 64-bit
    meson setup build -Denable-docs=false && \
    ninja -C build && \
    ninja -C build install && \
    rm -rf build && \
    # 32-bit
    echo "[binaries]\nc = '/usr/bin/gcc'\ncpp = '/usr/bin/g++'\nar = 'ar'\nstrip = 'strip'\npkgconfig = 'pkg-config'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'x86'\ncpu = 'i386'\nendian = 'little'" > /opt/build32-conf.txt && \
    export PKG_CONFIG_PATH="/usr/lib/i386-linux-gnu/pkgconfig" && \
    export LD_LIBRARY_PATH="/usr/lib/i386-linux-gnu" && \
    CFLAGS="-m32" LDFLAGS="-m32" meson setup build_i386 -Denable-docs=false --prefix=/usr/local/i386 --libdir=lib/i386-linux-gnu \
    --native-file /opt/build32-conf.txt && \
    ninja -C build_i386 && \
    ninja -C build_i386 install

ENV CC="clang" \
    CXX="clang++" \
    CFLAGS="-fPIC -static -fno-stack-protector -fno-stack-check" \
    CXXFLAGS="-fPIC -static -fno-stack-protector -fno-stack-check" \
    LDFLAGS="-static -fuse-ld=lld -static-libgcc -static-libstdc++" \
    PKG_CONFIG="pkg-config --static"

# xz and libunwind for the ntdll.so to not depend on libgcc and liblzma
RUN wget -O xz.tar.gz https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz && \
    tar -xf xz.tar.gz && \
    cd xz-${XZ_VERSION} && \
    mkdir build_static && \
    cd build_static && \
    ../configure --enable-static --disable-shared --prefix=/usr/local && \
    make -j$(nproc) && \
    make install

RUN wget -O libunwind.tar.gz https://github.com/libunwind/libunwind/releases/download/v${LIBUNWIND_VERSION}/libunwind-${LIBUNWIND_VERSION}.tar.gz && \
    tar -xf libunwind.tar.gz && \
    cd libunwind-${LIBUNWIND_VERSION} && \
    mkdir build_static && \
    cd build_static && \
    ../configure --enable-static --disable-shared --prefix=/usr/local \
        --disable-minidebuginfo \
        --disable-documentation \
        --disable-tests && \
    make -j$(nproc) && \
    make install

RUN apt-get clean && \
    apt-get autoclean && \
    rm -rf /build/* /var/lib/apt/lists/*

COPY build_wine.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/build_wine.sh
WORKDIR /wine
ENTRYPOINT ["/usr/local/bin/build_wine.sh"]