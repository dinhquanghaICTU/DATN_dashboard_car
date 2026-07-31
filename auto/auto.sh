#!/bin/bash
set -euo pipefail

cat << 'BANNER'
  ___  _   _   _    _   _  ____   _   _    _      ___ ____ _____ _   _
 / _ \| | | | / \  | \ | |/ ___| | | | |  / \    |_ _/ ___|_   _| | | |
| | | | | | |/ _ \ |  \| | |  _  | |_| | / _ \    | | |     | | | | | |
| |_| | |_| / ___ \| |\  | |_| |  |  _  |/ ___ \   | | |___  | | | |_| |
 \__\_\\___/_/   \_\_| \_|\____|  |_| |_/_/   \_\ |___\____| |_|  \___/

                         QUANG HA ICTU
BANNER

#luu y file config.txt o cung cap thu muc voi file.sh
CRED_FILE="config.txt"

# check file config.txt
if [ ! -r "$CRED_FILE" ]; then
  echo "Khong tim thay hoac khong the doc duoc file: $CRED_FILE" >&2
  exit 1
fi

#doc file, loai bo comment va dong trong thua
lines=()
while IFS= read -r rawline; do
  #Lam sach khoang trang 2 dau
  line="$(printf '%s' "$rawline" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  #Loai bo dong trong va comment
  if [ -z "$line" ] || [[ "$line" == \#* ]]; then
    continue
  fi
  lines+=("$line")
done < "$CRED_FILE"

HOST_USER="${lines[0]:-}"
HOST_PASS="${lines[1]:-}"
RASPI_USER="${lines[2]:-}"
RASPI_PASS="${lines[3]:-}"
RASPI_IP="${lines[4]:-}"

#Dinh nghia ten cac folder neu muon thay doi
#trong file nay dong 187, trong file cau hinh toolchain.cmake, co hardcode duong link, neu thay doi xin hay thay doi ca ben trong toolchain.cmake
FOLDER_WORK="Qt6Cross" #Folder cha, chua tat ca cac file ben trong
export FOLDER_WORK


printf '%s\n' "$HOST_PASS" | sudo -S -p '' apt update 
printf '%s\n' "$HOST_PASS" | sudo -S -p '' apt full-upgrade -y
printf '%s\n' "$HOST_PASS" | sudo -S -p '' apt install -y software-properties-common
printf '%s\n' "$HOST_PASS" | sudo -S -p '' add-apt-repository -y universe
printf '%s\n' "$HOST_PASS" | sudo -S -p '' apt update
printf '%s\n' "$HOST_PASS" | sudo -S -p '' apt install -y cmake
printf '%s\n' "$HOST_PASS" | sudo -S -p '' apt install -y $(tr -d '\r' < dep_list_host.txt)
printf '%s\n' "$HOST_PASS" | sudo -S -p '' apt install -y unzip

#=============================================SCRIPT SETUP BEN RASPI=============================================
sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
    "printf '%s\n' '$RASPI_PASS' | sudo -S -p '' apt update && printf '%s\n' '$RASPI_PASS' | sudo -S -p '' apt full-upgrade -y" 
    
PKGS="$(tr -d '\r' < dep_list_raspi.txt | tr '\n' ' ')"
sshpass -p "$RASPI_PASS" ssh -t -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
  "printf '%s\n' \"$RASPI_PASS\" | sudo -S -p '' apt install -y $PKGS"
  
sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
  "printf '%s\n' '$RASPI_PASS' | sudo -S -p '' mkdir -p /usr/local/qt6 && \
  printf '%s\n' '$RASPI_PASS' | sudo -S -p '' chown -R '${RASPI_USER}:${RASPI_USER}' /usr/local/qt6"

  
sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
  "grep -Fqx 'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/qt6/lib/' ~/.bashrc || \
  echo 'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/qt6/lib/' >> ~/.bashrc"

#================================================================================================================




#=============================================SCRIPT SETUP BEN HOST==============================================

# kiem tra nguoi chay script hien tai co cung sudo user trong config.txt khong
CUR_USER="$(id -un)"
if [ "$CUR_USER" != "$HOST_USER" ]; then
  echo "Script chi nen chay voi user duoc khai bao trong config.txt, nhung hien tai user dang chay script la '$CUR_USER'" >&2
  exit 1
fi

#tao folder lam viec rieng (folder chua tat ca)
cd ~
mkdir -p "$FOLDER_WORK"
cd "$FOLDER_WORK"

# CMake duoc cai tu repository cua Ubuntu o buoc dependency phia tren.


#tai gcc lam cross compiler 

#node quang ha loi ay 
if [ -x /opt/cross-pi-gcc/bin/aarch64-linux-gnu-g++ ]; then
  echo "[SKIP] Cross-compiler da ton tai: /opt/cross-pi-gcc/bin/aarch64-linux-gnu-g++"
else
cd ~/$FOLDER_WORK
mkdir -p gcc_all && cd gcc_all
GITHUB_RELEASE_URL="https://github.com/dinhquanghaICTU/DATN_dashboard_car/releases/download/v1.0.0"
wget -nc "$GITHUB_RELEASE_URL/binutils-2.35.2.tar.bz2"
wget -nc "$GITHUB_RELEASE_URL/glibc-2.31.tar.bz2"
wget -nc "$GITHUB_RELEASE_URL/gcc-10.3.0.tar.gz"
wget -nc "$GITHUB_RELEASE_URL/linux.zip"
[ -d binutils-2.35.2 ] || tar xf binutils-2.35.2.tar.bz2
[ -d glibc-2.31 ] || tar xf glibc-2.31.tar.bz2
[ -d gcc-10.3.0 ] || tar xf gcc-10.3.0.tar.gz
[ -d linux ] || unzip -q linux.zip
if [ ! -d linux ]; then
  echo "File linux.zip phai chua folder co ten la 'linux'." >&2
  exit 1
fi
rm -f ./*.tar.* linux.zip
cd gcc-10.3.0
contrib/download_prerequisites

#folder chua binaries cross compiler
printf '%s\n' "$HOST_PASS" | sudo -S -p '' mkdir -p /opt/cross-pi-gcc
printf '%s\n' "$HOST_PASS" | sudo -S -p '' chown $USER /opt/cross-pi-gcc
export PATH=/opt/cross-pi-gcc/bin:$PATH

#Cai dat kernel header cua raspi
cd ~/$FOLDER_WORK/gcc_all
cd linux
KERNEL=kernel7
make ARCH=arm64 INSTALL_HDR_PATH=/opt/cross-pi-gcc/aarch64-linux-gnu headers_install

#build và cài đặt binutils cho cross-compiler
cd ~/$FOLDER_WORK/gcc_all
mkdir -p build-binutils && cd build-binutils
../binutils-2.35.2/configure --prefix=/opt/cross-pi-gcc --target=aarch64-linux-gnu --with-arch=armv8 --disable-multilib
make -j 8
make install

ASAN_LINUX_FILE="$HOME/$FOLDER_WORK/gcc_all/gcc-10.3.0/libsanitizer/asan/asan_linux.cpp"
if ! grep -Fq '#define PATH_MAX 4096' "$ASAN_LINUX_FILE"; then
  sed -i '1i#ifndef PATH_MAX\n#define PATH_MAX 4096\n#endif' "$ASAN_LINUX_FILE"
fi


#build GCC cross-compiler chính
cd ~/$FOLDER_WORK/gcc_all
mkdir -p build-gcc && cd build-gcc
../gcc-10.3.0/configure --prefix=/opt/cross-pi-gcc --target=aarch64-linux-gnu --enable-languages=c,c++ --disable-multilib
make -j8 all-gcc
make install-gcc

#build và cài đặt glibc cho cross-compiler
cd ~/$FOLDER_WORK/gcc_all
mkdir -p build-glibc && cd build-glibc
../glibc-2.31/configure --prefix=/opt/cross-pi-gcc/aarch64-linux-gnu --build=$MACHTYPE --host=aarch64-linux-gnu --target=aarch64-linux-gnu --with-headers=/opt/cross-pi-gcc/aarch64-linux-gnu/include --disable-multilib libc_cv_forced_unwind=yes
make install-bootstrap-headers=yes install-headers
make -j8 csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o /opt/cross-pi-gcc/aarch64-linux-gnu/lib
aarch64-linux-gnu-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o /opt/cross-pi-gcc/aarch64-linux-gnu/lib/libc.so
touch /opt/cross-pi-gcc/aarch64-linux-gnu/include/gnu/stubs.h

#build thư viện runtime libgcc cho cross-compiler
cd ~/$FOLDER_WORK/gcc_all/build-gcc
make -j8 all-target-libgcc
make install-target-libgcc

#build glibc đầy đủ cho cross-compiler.
cd ~/$FOLDER_WORK/gcc_all/build-glibc
make -j8
make install

#build và cài đặt GCC hoàn chỉnh sau khi đã chuẩn bị glibc và libgcc
cd ~/$FOLDER_WORK/gcc_all/build-gcc
make -j8
make install
fi
#====================================================================================================================



#=============================================SCRIPT BUILD=======================================================

#buld Qt6 cho host
cd ~/$FOLDER_WORK
mkdir -p qt6/host qt6/pi qt6/host-build qt6/pi-build qt6/src

cd ~/$FOLDER_WORK/qt6/src
wget -nc https://download.qt.io/official_releases/qt/6.5/6.5.1/submodules/qtbase-everywhere-src-6.5.1.tar.xz
if [ ! -d qtbase-everywhere-src-6.5.1 ]; then
  tar xf qtbase-everywhere-src-6.5.1.tar.xz
fi

if [ -x "$HOME/$FOLDER_WORK/qt6/host/bin/qt-configure-module" ]; then
  echo "[SKIP] Qt host da duoc cai."
else
  cd "$HOME/$FOLDER_WORK/qt6/host-build/"
  cmake ../src/qtbase-everywhere-src-6.5.1/ -GNinja -DCMAKE_BUILD_TYPE=Release -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX="$HOME/$FOLDER_WORK/qt6/host"
  cmake --build . --parallel 8
  cmake --install .
fi



#Tao folder chua sysroot cua raspi
cd ~/$FOLDER_WORK
if [ -f "$HOME/$FOLDER_WORK/rpi-sysroot/.sysroot-ready" ]; then
  echo "[SKIP] Raspberry Pi sysroot da duoc dong bo."
else
  mkdir -p rpi-sysroot/usr/lib

  #Copy sysroot cua pi sang may host
  sshpass -p "$RASPI_PASS" rsync -avz --rsync-path="rsync" "${RASPI_USER}@${RASPI_IP}:/usr/include" rpi-sysroot/usr
  sshpass -p "$RASPI_PASS" rsync -avz --rsync-path="rsync" "${RASPI_USER}@${RASPI_IP}:/lib" rpi-sysroot
  sshpass -p "$RASPI_PASS" rsync -avz --exclude='/cups/backend/***' --rsync-path="rsync" "${RASPI_USER}@${RASPI_IP}:/usr/lib/" rpi-sysroot/usr/lib/

  #Sua chua symbol link, tranh bi loi link lien ket khi copy sysroot tu pi sang host
  wget -nc https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py
  chmod +x sysroot-relativelinks.py
  python3 sysroot-relativelinks.py rpi-sysroot
  touch rpi-sysroot/.sysroot-ready
fi

#Tao folder chua bien dich cheo cua qt
if [ -x "$HOME/$FOLDER_WORK/qt6/pi/bin/qt-configure-module" ]; then
  echo "[SKIP] QtBase target cho Raspberry Pi da duoc cai."
else
cd "$HOME/$FOLDER_WORK/qt6/pi-build"


cat << 'EOF' > toolchain.cmake
cmake_minimum_required(VERSION 3.18)
include_guard(GLOBAL)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# You should change location of sysroot to your needs.
set(TARGET_SYSROOT $ENV{HOME}/Qt6Cross/rpi-sysroot)
set(TARGET_ARCHITECTURE aarch64-linux-gnu)
set(CMAKE_SYSROOT ${TARGET_SYSROOT})

set(ENV{PKG_CONFIG_PATH} $PKG_CONFIG_PATH:${CMAKE_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE}/pkgconfig)
set(ENV{PKG_CONFIG_LIBDIR} /usr/lib/pkgconfig:/usr/share/pkgconfig/:${TARGET_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE}/pkgconfig:${TARGET_SYSROOT}/usr/lib/pkgconfig)
set(ENV{PKG_CONFIG_SYSROOT_DIR} ${CMAKE_SYSROOT})

set(CMAKE_C_COMPILER /opt/cross-pi-gcc/bin/${TARGET_ARCHITECTURE}-gcc)
set(CMAKE_CXX_COMPILER /opt/cross-pi-gcc/bin/${TARGET_ARCHITECTURE}-g++)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -isystem=/usr/include -isystem=/usr/local/include -isystem=/usr/include/${TARGET_ARCHITECTURE}")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS}")

set(QT_COMPILER_FLAGS "-march=armv8-a")
set(QT_COMPILER_FLAGS_RELEASE "-O2 -pipe")
set(QT_LINKER_FLAGS "-Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed -Wl,-rpath-link=${TARGET_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE} -Wl,-rpath-link=$ENV{HOME}/$ENV{FOLDER_WORK}/qt6/pi/lib")

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


cd $HOME/$FOLDER_WORK/qt6/pi-build

cmake ../src/qtbase-everywhere-src-6.5.1/ -GNinja -DCMAKE_BUILD_TYPE=Release -DINPUT_opengl=es2 -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_HOST_PATH=$HOME/$FOLDER_WORK/qt6/host -DCMAKE_STAGING_PREFIX=$HOME/$FOLDER_WORK/qt6/pi -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 -DCMAKE_TOOLCHAIN_FILE=$HOME/$FOLDER_WORK/qt6/pi-build/toolchain.cmake -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 -DQT_FEATURE_xcb=ON -DFEATURE_xcb_xlib=ON -DQT_FEATURE_xlib=ON

cmake --build . --parallel 8

cmake --install .
fi

sshpass -p "$RASPI_PASS" rsync -avz \
  "$HOME/$FOLDER_WORK/qt6/pi/" "${RASPI_USER}@${RASPI_IP}:/usr/local/qt6/"
#================================================================================================================

#=============================================CAI QT SHADER TOOLS===============================================
QT_VERSION="6.5.1"
QT_SRC_DIR="$HOME/$FOLDER_WORK/qt6/src"
QT_HOST_DIR="$HOME/$FOLDER_WORK/qt6/host"
QT_PI_DIR="$HOME/$FOLDER_WORK/qt6/pi"

QT_SHADERTOOLS_ARCHIVE="qtshadertools-everywhere-src-${QT_VERSION}.tar.xz"
QT_SHADERTOOLS_SOURCE="$QT_SRC_DIR/qtshadertools-everywhere-src-${QT_VERSION}"
QT_SHADERTOOLS_HOST_BUILD="$HOME/$FOLDER_WORK/qt6/host-build-qtshadertools"
QT_SHADERTOOLS_PI_BUILD="$HOME/$FOLDER_WORK/qt6/pi-build-qtshadertools"

cd "$QT_SRC_DIR"
wget -nc "https://download.qt.io/official_releases/qt/6.5/${QT_VERSION}/submodules/${QT_SHADERTOOLS_ARCHIVE}"
if [ ! -d "$QT_SHADERTOOLS_SOURCE" ]; then
  tar xf "$QT_SHADERTOOLS_ARCHIVE"
fi

mkdir -p "$QT_SHADERTOOLS_HOST_BUILD"
if [ -f "$QT_SHADERTOOLS_HOST_BUILD/.install-complete" ]; then
  echo "[SKIP] Qt Shader Tools cho host da duoc cai."
else
  cd "$QT_SHADERTOOLS_HOST_BUILD"
  "$QT_HOST_DIR/bin/qt-configure-module" "$QT_SHADERTOOLS_SOURCE" -- \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_SHADERTOOLS_HOST_BUILD/.install-complete"
fi

mkdir -p "$QT_SHADERTOOLS_PI_BUILD"
if [ -f "$QT_SHADERTOOLS_PI_BUILD/.install-complete" ]; then
  echo "[SKIP] Qt Shader Tools cho Raspberry Pi da duoc cai."
else
  cd "$QT_SHADERTOOLS_PI_BUILD"
  "$QT_PI_DIR/bin/qt-configure-module" "$QT_SHADERTOOLS_SOURCE" -- \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_SHADERTOOLS_PI_BUILD/.install-complete"
fi
#================================================================================================================

#=============================================CAI QT DECLARATIVE=================================================
QT_DECLARATIVE_ARCHIVE="qtdeclarative-everywhere-src-${QT_VERSION}.tar.xz"
QT_DECLARATIVE_SOURCE="$QT_SRC_DIR/qtdeclarative-everywhere-src-${QT_VERSION}"
QT_DECLARATIVE_HOST_BUILD="$HOME/$FOLDER_WORK/qt6/host-build-qtdeclarative"
QT_DECLARATIVE_PI_BUILD="$HOME/$FOLDER_WORK/qt6/pi-build-qtdeclarative"

cd "$QT_SRC_DIR"
wget -nc "https://download.qt.io/official_releases/qt/6.5/${QT_VERSION}/submodules/${QT_DECLARATIVE_ARCHIVE}"
if [ ! -d "$QT_DECLARATIVE_SOURCE" ]; then
  tar xf "$QT_DECLARATIVE_ARCHIVE"
fi

mkdir -p "$QT_DECLARATIVE_HOST_BUILD"
if [ -f "$QT_DECLARATIVE_HOST_BUILD/.install-complete" ]; then
  echo "[SKIP] Qt Declarative cho host da duoc cai."
else
  cd "$QT_DECLARATIVE_HOST_BUILD"
  "$QT_HOST_DIR/bin/qt-configure-module" "$QT_DECLARATIVE_SOURCE" -- \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_DECLARATIVE_HOST_BUILD/.install-complete"
fi

mkdir -p "$QT_DECLARATIVE_PI_BUILD"
if [ -f "$QT_DECLARATIVE_PI_BUILD/.install-complete" ]; then
  echo "[SKIP] Qt Declarative cho Raspberry Pi da duoc cai."
else
  cd "$QT_DECLARATIVE_PI_BUILD"
  "$QT_PI_DIR/bin/qt-configure-module" "$QT_DECLARATIVE_SOURCE" -- \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_DECLARATIVE_PI_BUILD/.install-complete"
fi
#================================================================================================================

#=============================================CAI QT SERIAL PORT=================================================
QT_SERIALPORT_ARCHIVE="qtserialport-everywhere-src-${QT_VERSION}.tar.xz"
QT_SERIALPORT_SOURCE="$QT_SRC_DIR/qtserialport-everywhere-src-${QT_VERSION}"
QT_SERIALPORT_HOST_BUILD="$HOME/$FOLDER_WORK/qt6/host-build-qtserialport"
QT_SERIALPORT_PI_BUILD="$HOME/$FOLDER_WORK/qt6/pi-build-qtserialport"

cd "$QT_SRC_DIR"
wget -nc "https://download.qt.io/official_releases/qt/6.5/${QT_VERSION}/submodules/${QT_SERIALPORT_ARCHIVE}"
if [ ! -d "$QT_SERIALPORT_SOURCE" ]; then
  tar xf "$QT_SERIALPORT_ARCHIVE"
fi

mkdir -p "$QT_SERIALPORT_HOST_BUILD"
if [ -f "$QT_SERIALPORT_HOST_BUILD/.install-complete" ]; then
  echo "[SKIP] Qt Serial Port cho host da duoc cai."
else
  cd "$QT_SERIALPORT_HOST_BUILD"
  "$QT_HOST_DIR/bin/qt-configure-module" "$QT_SERIALPORT_SOURCE" -- \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_SERIALPORT_HOST_BUILD/.install-complete"
fi

mkdir -p "$QT_SERIALPORT_PI_BUILD"
if [ -f "$QT_SERIALPORT_PI_BUILD/.install-complete" ]; then
  echo "[SKIP] Qt Serial Port cho Raspberry Pi da duoc cai."
else
  cd "$QT_SERIALPORT_PI_BUILD"
  "$QT_PI_DIR/bin/qt-configure-module" "$QT_SERIALPORT_SOURCE" -- \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_SERIALPORT_PI_BUILD/.install-complete"
fi
#================================================================================================================

# Dong bo toan bo Qt staging sang Raspberry Pi mot lan sau khi build xong cac module.
sshpass -p "$RASPI_PASS" rsync -avz \
  "$QT_PI_DIR/" "${RASPI_USER}@${RASPI_IP}:/usr/local/qt6/"
#================================================================================================================
#=============================================CAI DAT QT CREATOR================================================
QT_CREATOR_VERSION="10.0.1"
QT_CREATOR_DEB="qtcreator-linux-x64-${QT_CREATOR_VERSION}.deb"
QT_CREATOR_URL="https://github.com/qt-creator/qt-creator/releases/download/v${QT_CREATOR_VERSION}/${QT_CREATOR_DEB}"
QT_CREATOR_DIR="$HOME/$FOLDER_WORK/qtcreator"
QT_CREATOR_MARKER="$QT_CREATOR_DIR/.install-complete"

mkdir -p "$QT_CREATOR_DIR"
cd "$QT_CREATOR_DIR"

if [ -f "$QT_CREATOR_MARKER" ]; then
  echo "[SKIP] Qt Creator ${QT_CREATOR_VERSION} da duoc cai."
else
  wget -nc "$QT_CREATOR_URL"
  printf '%s\n' "$HOST_PASS" | sudo -S -p '' apt install -y "./$QT_CREATOR_DEB"
  touch "$QT_CREATOR_MARKER"
fi
#================================================================================================================