FROM sherrydck/proton-sdk-arm64:latest AS main-deps

FROM main-deps AS manual-deps

ENV FFMPEG_VERSION="7.1.1" \
    LIBXKBCOMMON_VERSION="1.9.2" \
    LIBXML2_VERSION="2.13.9" \
    GSTREAMER_VERSION="1.26.5" \
    XZ_VERSION="5.6.4" \
    LIBUNWIND_VERSION="1.8.3" \
    LIBGLVND_VERSION="1.7.0" \
    MESON_VERSION="1.9.1" \
    NINJA_VERSION="1.13.0" \
    RUSTUP_VERSION="1.28.2" \
    RUST_VERSION="1.91.0"

WORKDIR /build

RUN apt-get -y update && \
    apt-get -y install python3-pip && \
    pip3 install --upgrade pip && \
    pip3 install --upgrade meson==${MESON_VERSION} ninja==${NINJA_VERSION}

RUN wget -O rustup-init.sh https://raw.githubusercontent.com/rust-lang/rustup/${RUSTUP_VERSION}/rustup-init.sh && \
    chmod +x rustup-init.sh && \
    ./rustup-init.sh -y --default-toolchain ${RUST_VERSION} && \
    rm rustup-init.sh && \
    . "$HOME/.cargo/env" && \
    rustup component add rust-src rustfmt clippy && \
    ln -sf "$HOME/.cargo/bin/cargo" /usr/local/bin/cargo && \
    ln -sf "$HOME/.cargo/bin/rustc" /usr/local/bin/rustc && \
    ln -sf "$HOME/.cargo/bin/rustup" /usr/local/bin/rustup

RUN wget -O libunwind.tar.gz https://github.com/libunwind/libunwind/releases/download/v${LIBUNWIND_VERSION}/libunwind-${LIBUNWIND_VERSION}.tar.gz && \
    tar -xf libunwind.tar.gz && \
    cd libunwind-${LIBUNWIND_VERSION} && \
    mkdir build_static && \
    cd build_static && \
    CC=clang CXX=clang++ ../configure --enable-static --disable-shared --prefix=/usr/local \
        --disable-minidebuginfo \
        --disable-documentation \
        --disable-tests && \
    make -j$(nproc) && \
    make install

RUN wget -O libxkbcommon.tar.gz https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-${LIBXKBCOMMON_VERSION}.tar.gz && \
    tar -xf libxkbcommon.tar.gz && \
    cd libxkbcommon-xkbcommon-${LIBXKBCOMMON_VERSION} && \
    echo "[binaries]\nc = 'clang'\ncpp = 'clang++'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'aarch64'\ncpu = 'aarch64'\nendian = 'little'" > /opt/build-conf.txt && \
    export PKG_CONFIG_LIBDIR="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}" && \
    CC=clang CXX=clang++ CFLAGS="-static-libgcc -DHAVE_STRNDUP=1" CXXFLAGS="-static-libgcc -static-libstdc++ -DHAVE_STRNDUP=1" LDFLAGS="-static-libgcc -static-libstdc++" meson setup --prefer-static \
        --prefix=/usr/local --libdir=/usr/local/lib \
        --native-file /opt/build-conf.txt --buildtype "release" \
        build -Denable-docs=false -Ddefault_library=static -Denable-tools=false \
        -Denable-bash-completion=false -Denable-x11=false -Denable-wayland=false -Denable-xkbregistry=true && \
    meson compile -C build xkbcommon:static_library && \
    meson compile -C build xkbregistry:static_library && \
    meson install -C build --no-rebuild --tags devel

RUN wget -O libxml2.tar.gz https://github.com/GNOME/libxml2/archive/refs/tags/v${LIBXML2_VERSION}.tar.gz && \
    tar -xf libxml2.tar.gz && \
    cd libxml2-${LIBXML2_VERSION} && \
    export PKG_CONFIG_LIBDIR="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}" && \
    CC=clang CXX=clang++ CFLAGS="-fPIC -static-libgcc" CXXFLAGS="-fPIC -static-libgcc -static-libstdc++" LDFLAGS="-static-libgcc -static-libstdc++" \
    ./autogen.sh --prefix=/usr/local --libdir=/usr/local/lib \
    --enable-static --disable-shared \
    --without-python --without-lzma --without-zlib \
    --host=aarch64-linux-gnu && \
    make -j$(nproc) && \
    make install

RUN wget -O gstreamer.tar.gz https://github.com/GStreamer/gstreamer/archive/refs/tags/${GSTREAMER_VERSION}.tar.gz && \
    tar -xf gstreamer.tar.gz && \
    cd gstreamer-${GSTREAMER_VERSION} && \
    echo "[binaries]\nc = 'clang'\ncpp = 'clang++'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'aarch64'\ncpu = 'aarch64'\nendian = 'little'" > /opt/build-conf.txt && \
    export PKG_CONFIG_LIBDIR="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}" && \
    CC=clang CXX=clang++ meson setup build \
        --prefix=/usr/local \
        --libdir=/usr/local/lib \
        --native-file /opt/build-conf.txt \
        -Dintrospection=disabled -Dgobject-cast-checks=disabled -Dglib-asserts=disabled -Dglib-checks=disabled \
        -Dnls=disabled -Dexamples=disabled -Dtests=disabled -Ddoc=disabled \
        -Dbenchmarks=disabled -Dtools=disabled && \
    ninja -C build && \
    ninja -C build install

RUN wget -O ffmpeg.tar.xz https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz && \
    tar -xf ffmpeg.tar.xz && \
    cd ffmpeg-${FFMPEG_VERSION} && \
    CC=clang CXX=clang++ CFLAGS="-Os -static-libgcc" \
    LDFLAGS="-Os -static-libgcc" \
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
        --disable-hwaccels \
        --arch=aarch64 \
        --target-os=linux && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf ffmpeg-${FFMPEG_VERSION}

RUN wget -O libglvnd.tar.gz https://github.com/NVIDIA/libglvnd/archive/refs/tags/v${LIBGLVND_VERSION}.tar.gz && \
    tar -xf libglvnd.tar.gz && \
    cd libglvnd-${LIBGLVND_VERSION} && \
    echo "[binaries]\nc = 'clang'\ncpp = 'clang++'\nld = 'lld'\nar = 'llvm-ar'\nstrip = 'llvm-strip'\npkgconfig = 'pkg-config'\n\n[host_machine]\nsystem = 'linux'\ncpu_family = 'aarch64'\ncpu = 'aarch64'\nendian = 'little'" > /opt/build-conf.txt && \
    export PKG_CONFIG_LIBDIR="/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/share/pkgconfig" && \
    export PKG_CONFIG_PATH="${PKG_CONFIG_LIBDIR}" && \
    LDFLAGS="-fuse-ld=lld" meson setup build -Dgles1=false \
        --prefix=/usr/local --libdir=/usr/local/lib \
        --native-file /opt/build-conf.txt --buildtype "release" && \
    ninja -C build && \
    ninja -C build install

RUN wget -O xz.tar.gz https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz && \
    tar -xf xz.tar.gz && \
    cd xz-${XZ_VERSION} && \
    mkdir build_static && \
    cd build_static && \
    CC=clang CXX=clang++ ../configure --enable-static --disable-shared --prefix=/usr/local && \
    make -j$(nproc) && \
    make install

RUN wget -O /usr/include/linux/ntsync.h \
    https://raw.githubusercontent.com/zen-kernel/zen-kernel/refs/tags/v6.17-zen1/include/uapi/linux/ntsync.h

RUN apt-get -y update && \
    apt-get -y install gawk libkrb5-dev libpcap0.8 libpcap0.8-dev && \
    apt-get clean && apt-get autoclean && \
    rm -rf /build/* /var/lib/apt/lists/*

FROM manual-deps AS temp-layer

COPY wine_builder.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wine_builder.sh

WORKDIR /wine
