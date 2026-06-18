# Qt 6.5.1 Cross Compile: Ubuntu → Raspberry Pi 4

> **Các file cần thiết có thể dùng luôn:**
> [Google Drive](https://drive.google.com/drive/folders/1INfJcckDI_olr4NDbNYfu6JdJKIJMWz6?usp=sharing)

---

## I. Máy build (Raspberry Pi 4)

### Cập nhật hệ thống

```bash
sudo apt update
sudo apt upgrade
```

### Cài các gói phụ thuộc (batch 1)

```bash
sudo apt-get install libboost-all-dev libudev-dev libinput-dev libts-dev libmtdev-dev libjpeg-dev libfontconfig1-dev libssl-dev libdbus-1-dev libglib2.0-dev libxkbcommon-dev libegl1-mesa-dev libgbm-dev libgles2-mesa-dev mesa-common-dev libasound2-dev libpulse-dev gstreamer1.0-omx libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-alsa libvpx-dev libsrtp2-dev libsnappy-dev libnss3-dev "^libxcb.*" flex bison libxslt-dev ruby gperf libbz2-dev libcups2-dev libatkmm-1.6-dev libxi6 libxcomposite1 libfreetype6-dev libicu-dev libsqlite3-dev libxslt1-dev
```

### Cài các gói phụ thuộc (batch 2)

```bash
sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev libx11-dev freetds-dev libsqlite3-dev libpq-dev libiodbc2-dev firebird-dev libxext-dev libxcb1 libxcb1-dev libx11-xcb1 libx11-xcb-dev libxcb-keysyms1 libxcb-keysyms1-dev libxcb-image0 libxcb-image0-dev libxcb-shm0 libxcb-shm0-dev libxcb-icccm4 libxcb-icccm4-dev libxcb-sync1 libxcb-sync-dev libxcb-render-util0 libxcb-render-util0-dev libxcb-xfixes0-dev libxrender-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-glx0-dev libxi-dev libdrm-dev libxcb-xinerama0 libxcb-xinerama0-dev libatspi2.0-dev libxcursor-dev libxcomposite-dev libxdamage-dev libxss-dev libxtst-dev libpci-dev libcap-dev libxrandr-dev libdirectfb-dev libaudio-dev libxkbcommon-x11-dev gdbserver
```

### Tạo thư mục cài Qt6 và cấp quyền

```bash
sudo mkdir /usr/local/qt6
sudo chmod 777 /usr/local/bin
```

### Thêm đường dẫn thư viện vào bashrc

```bash
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/qt6/lib/' >> ~/.bashrc
source ~/.bashrc
```

---

## II. Máy host (Ubuntu 22.04.5)

### Cập nhật hệ thống

```bash
sudo apt update
sudo apt upgrade
```

### Cài các gói cần thiết cho host

```bash
sudo apt-get install make build-essential libclang-dev ninja-build gcc git bison python3 gperf pkg-config libfontconfig1-dev libfreetype6-dev libx11-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libatspi2.0-dev libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev build-essential gawk git texinfo bison file wget libssl-dev gdbserver gdb-multiarch libxcb-cursor-dev
```

### Tạo thư mục làm việc

```bash
cd ~
mkdir Qt6Cross
```

### Tải và build CMake

> Quá trình tải, build và install rất lâu — hãy kiên nhẫn chờ.

```bash
cd ~/Qt6Cross
git clone https://github.com/Kitware/CMake.git
cd CMake
./bootstrap && make -j8 && sudo make install
```

---

### 1.1 Toolchain biên dịch chéo (GCC)

```bash
cd ~/Qt6Cross
mkdir gcc_all && cd gcc_all
```

> Nếu đã có sẵn các file binutils, glibc, gcc, linux thì chép vào `gcc_all`.
> Nếu tải lỗi, xóa thư mục đó và tải lại — server đặt ở nước ngoài, dễ bị timeout.

```bash
wget https://ftpmirror.gnu.org/binutils/binutils-2.35.2.tar.bz2
wget https://ftpmirror.gnu.org/glibc/glibc-2.31.tar.bz2
wget https://ftpmirror.gnu.org/gcc/gcc-10.3.0/gcc-10.3.0.tar.gz
git clone --depth=1 https://github.com/raspberrypi/linux
```

#### Giải nén và auto config

```bash
tar xf binutils-2.35.2.tar.bz2
tar xf glibc-2.31.tar.bz2
tar xf gcc-10.3.0.tar.gz
rm *.tar.*
cd gcc-10.3.0
contrib/download_prerequisites
```

#### Tạo thư mục cài đặt cross-compiler

```bash
sudo mkdir -p /opt/cross-pi-gcc
sudo chown $USER /opt/cross-pi-gcc
export PATH=/opt/cross-pi-gcc/bin:$PATH
```

#### Cài kernel headers

> Sau bước này, `/opt/cross-pi-gcc/aarch64-linux-gnu/include` sẽ có đầy đủ header của kernel.

```bash
cd ~/Qt6Cross/gcc_all
cd linux
KERNEL=kernel7
make ARCH=arm64 INSTALL_HDR_PATH=/opt/cross-pi-gcc/aarch64-linux-gnu headers_install
```

#### Build và cài binutils

```bash
cd ~/Qt6Cross/gcc_all
mkdir build-binutils && cd build-binutils
../binutils-2.35.2/configure --prefix=/opt/cross-pi-gcc --target=aarch64-linux-gnu --with-arch=armv8 --disable-multilib
make -j8
make install
```

#### Fix lỗi PATH_MAX trong libsanitizer

> Trên một số hệ thống, `PATH_MAX` chưa được định nghĩa, gây lỗi build:
> `asan_linux.cpp: error: 'PATH_MAX' was not declared in this scope`

```bash
sed -i '1i#ifndef PATH_MAX\n#define PATH_MAX 4096\n#endif' ~/Qt6Cross/gcc_all/gcc-10.3.0/libsanitizer/asan/asan_linux.cpp
```

#### Build GCC cross-compiler

```bash
cd ~/Qt6Cross/gcc_all
mkdir build-gcc && cd build-gcc
../gcc-10.3.0/configure --prefix=/opt/cross-pi-gcc --target=aarch64-linux-gnu --enable-languages=c,c++ --disable-multilib
make -j8 all-gcc
make install-gcc
```

#### Build và cài glibc (bootstrap)

```bash
cd ~/Qt6Cross/gcc_all
mkdir build-glibc && cd build-glibc
../glibc-2.31/configure --prefix=/opt/cross-pi-gcc/aarch64-linux-gnu --build=$MACHTYPE --host=aarch64-linux-gnu --target=aarch64-linux-gnu --with-headers=/opt/cross-pi-gcc/aarch64-linux-gnu/include --disable-multilib libc_cv_forced_unwind=yes
make install-bootstrap-headers=yes install-headers
make -j8 csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o /opt/cross-pi-gcc/aarch64-linux-gnu/lib
aarch64-linux-gnu-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o /opt/cross-pi-gcc/aarch64-linux-gnu/lib/libc.so
touch /opt/cross-pi-gcc/aarch64-linux-gnu/include/gnu/stubs.h
```

#### Build libgcc

```bash
cd ~/Qt6Cross/gcc_all/build-gcc
make -j8 all-target-libgcc
make install-target-libgcc
```

#### Build glibc đầy đủ

```bash
cd ~/Qt6Cross/gcc_all/build-glibc
make -j8
make install
```

#### Build và cài GCC hoàn chỉnh

```bash
cd ~/Qt6Cross/gcc_all/build-gcc
make -j8
make install
```

---

### 1.2 Build Qt 6.5.1

> Các file rất nặng, cần mạng ổn định. Nếu tải lỗi, xóa thư mục đó và thử lại.

```bash
cd ~/Qt6Cross
mkdir qt6 qt6/host qt6/pi qt6/host-build qt6/pi-build qt6/src
```

```bash
cd ~/Qt6Cross/qt6/src
wget https://download.qt.io/official_releases/qt/6.5/6.5.1/submodules/qtbase-everywhere-src-6.5.1.tar.xz
tar xf qtbase-everywhere-src-6.5.1.tar.xz
```

#### Build Qt6 cho host

```bash
cd $HOME/Qt6Cross/qt6/host-build/
cmake ../src/qtbase-everywhere-src-6.5.1/ -GNinja -DCMAKE_BUILD_TYPE=Release -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$HOME/Qt6Cross/qt6/host
cmake --build . --parallel 8
cmake --install .
```

#### Đồng bộ sysroot từ Raspberry Pi

> Thay `<username>` và `<IP>` bằng thông tin Raspberry Pi của bạn.
> Nếu lỗi quyền, bỏ `sudo` trong `--rsync-path`.

```bash
cd ~/Qt6Cross
mkdir rpi-sysroot rpi-sysroot/usr

rsync -avz --rsync-path="sudo rsync" <username>@<IP>:/usr/include rpi-sysroot/usr
rsync -avz --rsync-path="sudo rsync" <username>@<IP>:/lib rpi-sysroot
rsync -avz --rsync-path="sudo rsync" <username>@<IP>:/usr/lib rpi-sysroot/usr
```

```bash
wget https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py
chmod +x sysroot-relativelinks.py
python3 sysroot-relativelinks.py rpi-sysroot
```

#### Tạo file toolchain.cmake

```bash
cd $HOME/Qt6Cross/qt6/pi-build

cat << 'EOF' > toolchain.cmake
cmake_minimum_required(VERSION 3.18)
include_guard(GLOBAL)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Thay đổi đường dẫn sysroot cho phù hợp
set(TARGET_SYSROOT $ENV{HOME}/Qt6Cross/rpi-sysroot)
set(TARGET_ARCHITECTURE aarch64-linux-gnu)
set(CMAKE_SYSROOT ${TARGET_SYSROOT})

set(ENV{PKG_CONFIG_PATH} $PKG_CONFIG_PATH:${CMAKE_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE}/pkgconfig)
set(ENV{PKG_CONFIG_LIBDIR} /usr/lib/pkgconfig:/usr/share/pkgconfig/:${CMAKE_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE}/pkgconfig:${CMAKE_SYSROOT}/usr/lib/pkgconfig)
set(ENV{PKG_CONFIG_SYSROOT_DIR} ${CMAKE_SYSROOT})

set(CMAKE_C_COMPILER /opt/cross-pi-gcc/bin/${TARGET_ARCHITECTURE}-gcc)
set(CMAKE_CXX_COMPILER /opt/cross-pi-gcc/bin/${TARGET_ARCHITECTURE}-g++)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -isystem=/usr/include -isystem=/usr/local/include -isystem=/usr/include/${TARGET_ARCHITECTURE}")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}")

set(QT_COMPILER_FLAGS "-march=armv8-a")
set(QT_COMPILER_FLAGS_RELEASE "-O2 -pipe")
set(QT_LINKER_FLAGS "-Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed -Wl,-rpath-link=${TARGET_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE} -Wl,-rpath-link=$HOME/qt6/pi/lib")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_BUILD_RPATH ${TARGET_SYSROOT})

include(CMakeInitializeConfigs)

function(cmake_initialize_per_config_variable _PREFIX _DOCSTRING)
  if (_PREFIX MATCHES "CMAKE_(C|CXX|ASM)_FLAGS")
    set(CMAKE_${CMAKE_MATCH_1}_FLAGS_INIT "${QT_COMPILER_FLAGS}")
    foreach (config DEBUG RELEASE MINSIZEREL RELWITHDEBINFO)
      if (DEFINED QT_COMPILER_FLAGS_${config})
        set(CMAKE_${CMAKE_MATCH_1}_FLAGS_${config}_INIT "${QT_COMPILER_FLAGS_${config}}")
      endif()
    endforeach()
  endif()
  if (_PREFIX MATCHES "CMAKE_(SHARED|MODULE|EXE)_LINKER_FLAGS")
    foreach (config SHARED MODULE EXE)
      set(CMAKE_${config}_LINKER_FLAGS_INIT "${QT_LINKER_FLAGS}")
    endforeach()
  endif()
  _cmake_initialize_per_config_variable(${ARGV})
endfunction()

set(XCB_PATH_VARIABLE ${TARGET_SYSROOT})
set(GL_INC_DIR ${TARGET_SYSROOT}/usr/include)
set(GL_LIB_DIR ${TARGET_SYSROOT}:${TARGET_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE}/:${TARGET_SYSROOT}/usr:${TARGET_SYSROOT}/usr/lib)

set(EGL_INCLUDE_DIR ${GL_INC_DIR})
set(EGL_LIBRARY ${XCB_PATH_VARIABLE}/usr/lib/${TARGET_ARCHITECTURE}/libEGL.so)

set(OPENGL_INCLUDE_DIR ${GL_INC_DIR})
set(OPENGL_opengl_LIBRARY ${XCB_PATH_VARIABLE}/usr/lib/${TARGET_ARCHITECTURE}/libOpenGL.so)

set(GLESv2_INCLUDE_DIR ${GL_INC_DIR})
set(GLIB_LIBRARY ${XCB_PATH_VARIABLE}/usr/lib/${TARGET_ARCHITECTURE}/libGLESv2.so)

set(GLESv2_INCLUDE_DIR ${GL_INC_DIR})
set(GLESv2_LIBRARY ${XCB_PATH_VARIABLE}/usr/lib/${TARGET_ARCHITECTURE}/libGLESv2.so)

set(gbm_INCLUDE_DIR ${GL_INC_DIR})
set(gbm_LIBRARY ${XCB_PATH_VARIABLE}/usr/lib/${TARGET_ARCHITECTURE}/libgbm.so)

set(Libdrm_INCLUDE_DIR ${GL_INC_DIR})
set(Libdrm_LIBRARY ${XCB_PATH_VARIABLE}/usr/lib/${TARGET_ARCHITECTURE}/libdrm.so)

set(XCB_XCB_INCLUDE_DIR ${GL_INC_DIR})
set(XCB_XCB_LIBRARY ${XCB_PATH_VARIABLE}/usr/lib/${TARGET_ARCHITECTURE}/libxcb.so)

list(APPEND CMAKE_LIBRARY_PATH ${CMAKE_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE})
list(APPEND CMAKE_PREFIX_PATH "/usr/lib/${TARGET_ARCHITECTURE}/cmake")
EOF
```

#### Biên dịch Qt6 cho Raspberry Pi

```bash
cd $HOME/Qt6Cross/qt6/pi-build
cmake ../src/qtbase-everywhere-src-6.5.1/ -GNinja -DCMAKE_BUILD_TYPE=Release -DINPUT_opengl=es2 -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_HOST_PATH=$HOME/Qt6Cross/qt6/host -DCMAKE_STAGING_PREFIX=$HOME/Qt6Cross/qt6/pi -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 -DCMAKE_TOOLCHAIN_FILE=$HOME/Qt6Cross/qt6/pi-build/toolchain.cmake -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 -DQT_FEATURE_xcb=ON -DFEATURE_xcb_xlib=ON -DQT_FEATURE_xlib=ON
cmake --build . --parallel 8
cmake --install .
```

#### Gửi binaries sang Raspberry Pi

> Nếu lỗi quyền, bỏ `sudo` trong `--rsync-path`.

```bash
rsync -avz --rsync-path="sudo rsync" $HOME/Qt6Cross/qt6/pi/* <username>@<IP>:/usr/local/qt6
```

---

## III. Thêm các Qt module khác

> Danh sách module: https://download.qt.io/official_releases/qt/6.5/6.5.1/submodules/
> Chọn file `.tar.xz`.
> Ví dụ dưới đây dùng `qtdeclarative` — thay tên cho phù hợp.

### Build module mới cho host

```bash
cd ~/Qt6Cross/qt6/src
wget https://download.qt.io/official_releases/qt/6.5/6.5.1/submodules/<tên-module>.tar.xz
tar xf <tên-module>.tar.xz

cd ..
mkdir host-build-<tên-module>
cd host-build-<tên-module>

cmake ../src/<tên-module-đã-giải-nén>/ -GNinja -DCMAKE_BUILD_TYPE=Release -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$HOME/Qt6Cross/qt6/host
cmake --build . --parallel 8
cmake --install .
```

### Rebuild cho Raspberry Pi với module mới

```bash
cd $HOME/Qt6Cross/qt6/pi-build
rm -rf *
```

> Tạo lại `toolchain.cmake` (xem nội dung ở mục [Tạo file toolchain.cmake](#tạo-file-toolchancmake) phía trên), sau đó chạy:

```bash
cd $HOME/Qt6Cross/qt6/pi-build
cmake ../src/<tên-module-đã-giải-nén>/ -GNinja -DCMAKE_BUILD_TYPE=Release -DINPUT_opengl=es2 -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_HOST_PATH=$HOME/Qt6Cross/qt6/host -DCMAKE_STAGING_PREFIX=$HOME/Qt6Cross/qt6/pi -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 -DCMAKE_TOOLCHAIN_FILE=$HOME/Qt6Cross/qt6/pi-build/toolchain.cmake -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 -DQT_FEATURE_xcb=ON -DFEATURE_xcb_xlib=ON -DQT_FEATURE_xlib=ON
cmake --build . --parallel 8
cmake --install .
```

### Đồng bộ lại sang Raspberry Pi

```bash
rsync -avz --rsync-path="sudo rsync" $HOME/Qt6Cross/qt6/pi/* <username>@<IP>:/usr/local/qt6
```

---

## IV. Cài đặt Qt Creator

> Cần tải phiên bản Qt Creator phù hợp. Xem thêm trong file hướng dẫn đi kèm.

```bash
git clone git://code.qt.io/qt-creator/qt-creator.git
git log --cherry-pick --pretty=oneline origin/v10.0.0..v10.0.1
```