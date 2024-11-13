FROM ubuntu:focal AS main-deps

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/usr/local/llvm-mingw/bin:/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin" \
    MIRROR="http://archive.ubuntu.com/ubuntu/"

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
    jq        libgl-dev    libglvnd-dev   gcc-13-multilib  xserver-xorg-dev    libswscale-dev:i386 \
    flex      libllvm12    libglx0:i386   libavdevice-dev  libegl1-mesa-dev    libxcb-xkb-dev:i386 \
    gawk      libxi-dev    liblcms2-dev   libegl-dev:i386  libcupsimage2-dev   libxcursor-dev:i386 \
    nano      libvulkan1   libpulse-dev   libgcrypt20-dev  libgles2-mesa-dev   libavcodec-dev:i386 \
    nasm      samba-libs   libvkd3d-dev   libgl1-mesa-dev  libglu1-mesa:i386   libavdevice-dev:i386 \
    cargo     libcolord2   docbook-utils  libglx-dev:i386  libglvnd-dev:i386   libgl1-mesa-dev:i386 \
    meson     libegl-dev   glslang-tools  libgnutls28-dev  liblcms2-dev:i386   libgnutls28-dev:i386 \
    rustc     libgif-dev   libavutil-dev  libibus-1.0-dev  libpulse-dev:i386   libibus-1.0-dev:i386 \
    cmake     libglx-dev   libcapi20-dev  libosmesa6:i386  libswresample-dev   libxinerama-dev:i386 \
    bison     libosmesa6   libdbus-1-dev  libv4l-dev:i386  libvkd3d-dev:i386   mesa-common-dev:i386 \
    ccache    libpng-dev   libmpg123-dev  libvulkan1:i386  libxcomposite-dev   libegl1-mesa-dev:i386 \
    g++-13    libssl-dev   libopenal-dev  libxinerama-dev  libxslt1-dev:i386   libfreetype6-dev:i386 \
    gcc-13    libv4l-dev   libunwind-dev  mesa-common-dev  wayland-protocols   libglu1-mesa-dev:i386 \
    libgl1    libacl1-dev  libvulkan-dev  build-essential  desktop-file-utils  libunistring-dev:i386 \
    gettext   libgl1:i386  libxrandr-dev  g++-13-multilib  libavutil-dev:i386  libusb-1.0-0-dev:i386 \
    libglx0   libgles-dev  libavcodec-dev libfreetype6-dev libcapi20-dev:i386  libcupsimage2-dev:i386 \
    prelink   libgsm1-dev  libgl-dev:i386 libgpg-error-dev libdbus-1-dev:i386  libgles2-mesa-dev:i386 \
    jadetex   libkrb5-dev  libgphoto2-dev libgles-dev:i386 libfontconfig1-dev  libswresample-dev:i386 \
    autoconf  libldap-dev  libllvm12:i386 libglu1-mesa-dev libmpg123-dev:i386  libxcomposite-dev:i386 \
    libppl14  libpcap-dev  libncurses-dev libgsm1-dev:i386 libopenal-dev:i386  libfontconfig1-dev:i386 \
    oss4-dev  libsane-dev  libosmesa6-dev libldap-dev:i386 libunwind-dev:i386  ocl-icd-opencl-dev:i386 \
    valgrind  libsdl2-dev  libswscale-dev libpcap-dev:i386 libvulkan-dev:i386  libgstreamer1.0-dev:i386 \
    libxt-dev libtiff-dev  libwayland-dev libsane-dev:i386 libxrandr-dev:i386  libwayland-egl-backend-dev \
    mingw-w64 libudev-dev  libxcb-xkb-dev libsdl2-dev:i386 ocl-icd-opencl-dev  libwayland-egl-backend-dev:i386 \
    samba-dev libxml2-dev  libxcursor-dev libtiff-dev:i386 libsystemd-dev:i386 libgstreamer-plugins-base1.0-dev \
    schedtool libxslt1-dev libxi-dev:i386 libudev-dev:i386 libgphoto2-dev:i386 libgstreamer-plugins-base1.0-dev:i386 \
    sharutils unixodbc-dev linux-libc-dev libunistring-dev libgstreamer1.0-dev \
    fontforge libcups2-dev libsystemd-dev libusb-1.0-0-dev libncurses-dev:i386 \
    fonttools libglu1-mesa libasound2-dev libxml2-dev:i386 libosmesa6-dev:i386

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 90 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-13 \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-13

FROM main-deps AS manual-deps

ENV FFMPEG_VERSION="7.0.2" \
    LIBXKBCOMMON_VERSION="1.7.0" \
    LLVM_MINGW_VERSION="20241030" \
    XZ_VERSION="5.6.3" \
    LIBUNWIND_VERSION="1.8.1"

RUN wget -O llvm-mingw-${LLVM_MINGW_VERSION}.tar.xz \
    https://github.com/mstorsjo/llvm-mingw/releases/download/${LLVM_MINGW_VERSION}/llvm-mingw-${LLVM_MINGW_VERSION}-msvcrt-ubuntu-20.04-x86_64.tar.xz && \
    tar -xf llvm-mingw-${LLVM_MINGW_VERSION}.tar.xz -C /usr/local && \
    rm -rf /usr/local/llvm-mingw && \
    mv /usr/local/llvm-mingw-${LLVM_MINGW_VERSION}-msvcrt-ubuntu-20.04-x86_64 /usr/local/llvm-mingw

WORKDIR /build

RUN wget -O libxkbcommon.tar.xz https://xkbcommon.org/download/libxkbcommon-${LIBXKBCOMMON_VERSION}.tar.xz && \
    tar -xf libxkbcommon.tar.xz && \
    cd libxkbcommon-${LIBXKBCOMMON_VERSION} && \
    export LIBRARY_PATH="/usr/local/llvm-mingw/lib:/usr/lib:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/lib/x86_64-linux-gnu:/usr/local/i386/lib/i386-linux-gnu:/usr/local/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:${LIBRARY_PATH:-}" && \
    export LD_LIBRARY_PATH="/usr/local/llvm-mingw/lib:/usr/lib:/usr/lib/x86_64-linux-gnu:/usr/local/lib:/usr/local/lib/x86_64-linux-gnu:/usr/local/i386/lib/i386-linux-gnu:/usr/local/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:${LD_LIBRARY_PATH:-}" && \
    # 64-bit
    echo "[binaries]\nc = 'clang'\ncpp = 'clang++'\nld = 'lld'\nar = 'llvm-ar'\nstrip = 'llvm-strip'\npkgconfig = 'pkg-config'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'x86'\ncpu = 'x86_64'\nendian = 'little'" > /opt/build64-conf.txt && \
    export PKG_CONFIG_LIBDIR="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}" && \
    LDFLAGS="-fuse-ld=lld" meson setup build_x86_64 -Denable-docs=false \
        --prefix=/usr/local/x86_64 --libdir=/usr/local/x86_64/lib/x86_64-linux-gnu \
        --native-file /opt/build64-conf.txt && \
    ninja -C build_x86_64 && \
    ninja -C build_x86_64 install && \
    rm -rf build_x86_64 && \
    # 32-bit
    echo "[binaries]\nc = 'clang'\ncpp = 'clang++'\nld = 'lld'\nar = 'llvm-ar'\nstrip = 'llvm-strip'\npkgconfig = 'pkg-config'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'x86'\ncpu = 'i386'\nendian = 'little'" > /opt/build32-conf.txt && \
    export PKG_CONFIG_LIBDIR="/usr/lib/i386-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/local/i386/lib/i386-linux-gnu/pkgconfig:/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}" && \
    CFLAGS="-m32" LDFLAGS="-m32 -fuse-ld=lld" meson setup build_i386 -Denable-docs=false \
        --prefix=/usr/local/i386 --libdir=/usr/local/i386/lib/i386-linux-gnu \
        --native-file /opt/build32-conf.txt && \
    ninja -C build_i386 && \
    ninja -C build_i386 install

RUN wget -O ffmpeg.tar.xz https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz && \
    tar -xf ffmpeg.tar.xz && \
    cd ffmpeg-${FFMPEG_VERSION} && \
    # 64-bit build
    ./configure \
        --prefix=/usr/local \
        --enable-shared \
        --enable-static \
        --disable-doc \
        --disable-programs \
        --disable-encoders \
        --disable-muxers \
        --disable-filters \
        --enable-gpl \
        --enable-version3 \
        --disable-debug \
        --enable-nonfree \
        --disable-hwaccels && \
    make -j$(nproc) && \
    make install && \
    make clean && \
    # 32-bit build
    CFLAGS="-m32" \
    LDFLAGS="-m32" \
    PKG_CONFIG_PATH="/usr/lib/i386-linux-gnu/pkgconfig" \
    ./configure \
        --prefix=/usr/local/i386 \
        --libdir=/usr/local/i386/lib/i386-linux-gnu \
        --enable-shared \
        --enable-static \
        --disable-doc \
        --disable-programs \
        --disable-encoders \
        --disable-muxers \
        --disable-filters \
        --enable-gpl \
        --enable-version3 \
        --disable-debug \
        --enable-nonfree \
        --disable-hwaccels \
        --arch=x86_32 \
        --target-os=linux \
        --cross-prefix= \
        --disable-asm && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf ffmpeg-${FFMPEG_VERSION}

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

RUN python3 -m pip install afdko

RUN apt-get clean && \
    apt-get autoclean && \
    rm -rf /build/* /var/lib/apt/lists/*

COPY build_wine.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/build_wine.sh
WORKDIR /wine
ENTRYPOINT ["/usr/local/bin/build_wine.sh"]