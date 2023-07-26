FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.utf8

RUN apt-get update -qq && apt-get -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
  git-core \
  libass-dev \
  libfreetype6-dev \
  libgnutls28-dev \
  libmp3lame-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  meson \
  ninja-build \
  pkg-config \
  texinfo \
  wget \
  yasm \
  zlib1g-dev

RUN mkdir -p ~/ffmpeg_sources ~/bin

RUN cd ~/ffmpeg_sources && \
wget https://restless-recipe.driveindex.workers.dev/0:/nasm-2.15.05.tar.bz2 && \
tar xjvf nasm-2.15.05.tar.bz2 && \
cd nasm-2.15.05 && \
./autogen.sh && \
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && \
make -j$(cat /proc/cpuinfo | grep processor | wc -l) && \
make install && \
make clean

RUN cd ~/ffmpeg_sources && \
git -C x264 pull 2> /dev/null || git clone --depth 1 https://code.videolan.org/videolan/x264.git && \
cd x264 && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --enable-pic && \
PATH="$HOME/bin:$PATH" && \
make -j$(cat /proc/cpuinfo | grep processor | wc -l) && \
make install && \
make clean

RUN apt-get -y install libnuma-dev libunistring-dev libaom-dev && \
cd ~/ffmpeg_sources && \
wget -O x265.tar.bz2 https://bitbucket.org/multicoreware/x265_git/get/master.tar.bz2 && \
tar xjvf x265.tar.bz2 && \
cd multicoreware*/build/linux && \
PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED=off ../../source && \
PATH="$HOME/bin:$PATH" && \
make -j$(cat /proc/cpuinfo | grep processor | wc -l) && \
make install && \
make clean

RUN cd ~/ffmpeg_sources && \
git -C libvpx pull 2> /dev/null || git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
cd libvpx && \
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm && \
PATH="$HOME/bin:$PATH" && \
make -j$(cat /proc/cpuinfo | grep processor | wc -l) && \
make install && \
make distclean

RUN cd ~/ffmpeg_sources && \
git -C fdk-aac pull 2> /dev/null || git clone --depth 1 https://github.com/mstorsjo/fdk-aac && \
cd fdk-aac && \
autoreconf -fiv && \
./configure --prefix="$HOME/ffmpeg_build" --disable-shared && \
make -j$(cat /proc/cpuinfo | grep processor | wc -l) && \
make install && \
make distclean

RUN cd ~/ffmpeg_sources && \
git -C opus pull 2> /dev/null || git clone --depth 1 https://github.com/xiph/opus.git && \
cd opus && \
./autogen.sh && \
./configure --prefix="$HOME/ffmpeg_build" --disable-shared && \
make -j$(cat /proc/cpuinfo | grep processor | wc -l) && \
make install && \
make distclean

RUN cd ~/ffmpeg_sources && \
wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && \
tar xjvf ffmpeg-snapshot.tar.bz2 >/dev/null && \
cd ffmpeg && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --enable-gpl \
  --enable-gnutls \
  --enable-libaom \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --ld="g++" \
  --bindir="$HOME/bin" && \
PATH="$HOME/bin:$PATH" make -j$(cat /proc/cpuinfo | grep processor | wc -l) && \
make install && \
make distclean && \
hash -r

CMD bin/bash
