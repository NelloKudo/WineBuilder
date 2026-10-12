FROM registry.gitlab.steamos.cloud/proton/steamrt4/sdk/arm64-llvm:4.0.20260714.251823-0 AS main-deps

ENV DEBIAN_FRONTEND=noninteractive

FROM main-deps AS manual-deps

ENV FFMPEG_VERSION="7.1.1" \
    LIBXKBCOMMON_VERSION="1.13.1" \
    GSTREAMER_VERSION="1.26.5" \
    XZ_VERSION="5.8.3" \
    LIBUNWIND_VERSION="1.8.3"

WORKDIR /build

RUN apt-get -y update && \
    apt-get -y install gawk libfaad-dev libpcap0.8-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O libxkbcommon.tar.gz https://github.com/xkbcommon/libxkbcommon/archive/refs/tags/xkbcommon-${LIBXKBCOMMON_VERSION}.tar.gz && \
    tar -xf libxkbcommon.tar.gz && \
    cd libxkbcommon-xkbcommon-${LIBXKBCOMMON_VERSION} && \
    CFLAGS="-fPIC" meson setup --prefer-static \
        --prefix=/usr/local --libdir=/usr/local/lib --buildtype "release" \
        build -Denable-docs=false -Ddefault_library=static -Denable-tools=false \
        -Denable-bash-completion=false -Denable-x11=false -Denable-wayland=false -Denable-xkbregistry=true && \
    meson compile -C build xkbcommon:static_library && \
    meson compile -C build xkbregistry:static_library && \
    meson install -C build --no-rebuild --tags devel

RUN wget -O gstreamer.tar.gz https://github.com/GStreamer/gstreamer/archive/refs/tags/${GSTREAMER_VERSION}.tar.gz && \
    tar -xf gstreamer.tar.gz && \
    cd gstreamer-${GSTREAMER_VERSION} && \
    LDFLAGS="-Wl,-rpath,\$ORIGIN" meson setup build \
        --prefix=/usr/local --libdir=/usr/local/lib \
        -Dintrospection=disabled -Dgobject-cast-checks=disabled -Dglib-asserts=disabled -Dglib-checks=disabled \
        -Dnls=disabled -Dexamples=disabled -Dtests=disabled -Dgpl=enabled -Ddoc=disabled \
        -Dbenchmarks=disabled -Dtools=disabled -Dbad=enabled -Dgst-plugins-bad:faad=enabled \
        -Dges=disabled -Dlibav=disabled -Dlibnice=disabled -Dpython=disabled -Dqt5=disabled -Dqt6=disabled \
        -Drs=disabled -Drtsp_server=disabled -Dsharp=disabled -Dugly=disabled -Dvaapi=disabled \
        -Dgstreamer:ptp-helper=disabled -Ddevtools=disabled -Dgst-examples=disabled && \
    ninja -C build && \
    ninja -C build install

RUN wget -O ffmpeg.tar.xz https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz && \
    tar -xf ffmpeg.tar.xz && \
    cd ffmpeg-${FFMPEG_VERSION} && \
    ./configure \
        --prefix=/usr/local \
        --cc=clang --cxx=clang++ \
        --extra-cflags="-Os" \
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
    make install

RUN wget -O xz.tar.gz https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz && \
    tar -xf xz.tar.gz && \
    cd xz-${XZ_VERSION} && \
    mkdir build_static && \
    cd build_static && \
    CFLAGS="-Os -fPIC" ../configure --enable-static --disable-shared --prefix=/usr/local && \
    make -j$(nproc) && \
    make install

RUN wget -O libunwind.tar.gz https://github.com/libunwind/libunwind/releases/download/v${LIBUNWIND_VERSION}/libunwind-${LIBUNWIND_VERSION}.tar.gz && \
    tar -xf libunwind.tar.gz && \
    cd libunwind-${LIBUNWIND_VERSION} && \
    mkdir build_static && \
    cd build_static && \
    CFLAGS="-Os -fPIC" ../configure --enable-static --disable-shared --prefix=/usr/local \
        --disable-minidebuginfo \
        --disable-documentation \
        --disable-tests && \
    make -j$(nproc) && \
    make install

RUN rm -rf /build/*

FROM manual-deps AS temp-layer

COPY wine_builder.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wine_builder.sh

WORKDIR /wine
