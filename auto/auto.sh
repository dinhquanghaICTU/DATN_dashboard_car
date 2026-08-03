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
# Tam thoi bo qua viec cap nhat va cai dependency tren Raspberry Pi.
# Dat SKIP_RASPI_APT_SETUP=0 neu muon bat lai buoc nay.
SKIP_RASPI_APT_SETUP="${SKIP_RASPI_APT_SETUP:-1}"
if [ "$SKIP_RASPI_APT_SETUP" = "1" ]; then
  echo "[SKIP] Bo qua apt update/full-upgrade va cai dependency tren Raspberry Pi."
else
  sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
      "printf '%s\n' '$RASPI_PASS' | sudo -S -p '' apt update && printf '%s\n' '$RASPI_PASS' | sudo -S -p '' apt full-upgrade -y"

  PKGS="$(tr -d '\r' < dep_list_raspi.txt | tr '\n' ' ')"
  sshpass -p "$RASPI_PASS" ssh -t -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
    "printf '%s\n' \"$RASPI_PASS\" | sudo -S -p '' apt install -y $PKGS"
fi

# Cho phep user chay app truy cap DRM/KMS, GPU render, input va GPIO ma khong
# can chay toan bo ung dung bang root. Can tao phien dang nhap moi de co hieu luc.
sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
  "printf '%s\n' '$RASPI_PASS' | sudo -S -p '' usermod -aG video,render,input,gpio '${RASPI_USER}'"
  
sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
  "printf '%s\n' '$RASPI_PASS' | sudo -S -p '' mkdir -p /usr/local/qt6 && \
  printf '%s\n' '$RASPI_PASS' | sudo -S -p '' chown -R '${RASPI_USER}:${RASPI_USER}' /usr/local/qt6"

  
sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
  "grep -Fqx 'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/qt6/lib/' ~/.bashrc || \
  echo 'export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/qt6/lib/' >> ~/.bashrc"

# pigpiod_if2 la client cua daemon pigpiod (TCP 8888). Cai package chi tao
# service, khong dam bao service da duoc bat/chay.
sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
  "printf '%s\n' '$RASPI_PASS' | sudo -S -p '' systemctl enable --now pigpiod && \
  systemctl is-active --quiet pigpiod"

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

if [ -d binutils-2.35.2 ]; then
  echo "[SKIP] Source binutils-2.35.2 da ton tai."
else
  [ -f binutils-2.35.2.tar.bz2 ] || wget "$GITHUB_RELEASE_URL/binutils-2.35.2.tar.bz2"
  tar xf binutils-2.35.2.tar.bz2
fi

if [ -d glibc-2.31 ]; then
  echo "[SKIP] Source glibc-2.31 da ton tai."
else
  [ -f glibc-2.31.tar.bz2 ] || wget "$GITHUB_RELEASE_URL/glibc-2.31.tar.bz2"
  tar xf glibc-2.31.tar.bz2
fi

if [ -d gcc-10.3.0 ]; then
  echo "[SKIP] Source gcc-10.3.0 da ton tai."
else
  [ -f gcc-10.3.0.tar.gz ] || wget "$GITHUB_RELEASE_URL/gcc-10.3.0.tar.gz"
  tar xf gcc-10.3.0.tar.gz
fi

if [ -d linux ]; then
  echo "[SKIP] Source linux da ton tai."
else
  [ -f linux.zip ] || wget "$GITHUB_RELEASE_URL/linux.zip"
  unzip -q linux.zip
fi

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
SYSROOT_AUXV_HEADER="$HOME/$FOLDER_WORK/rpi-sysroot/usr/include/aarch64-linux-gnu/bits/auxv.h"
if [ -f "$HOME/$FOLDER_WORK/rpi-sysroot/.sysroot-ready" ] && [ -f "$SYSROOT_AUXV_HEADER" ]; then
  echo "[SKIP] Raspberry Pi sysroot da duoc dong bo."
else
  mkdir -p rpi-sysroot/usr/lib

  PI_ARCH="$(sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" "dpkg --print-architecture")"
  if [ "$PI_ARCH" != "arm64" ]; then
    echo "Raspberry Pi userland phai la arm64, nhung hien tai la: $PI_ARCH" >&2
    exit 1
  fi

  #Copy sysroot cua pi sang may host
  sshpass -p "$RASPI_PASS" rsync -avz --rsync-path="rsync" "${RASPI_USER}@${RASPI_IP}:/usr/include" rpi-sysroot/usr
  sshpass -p "$RASPI_PASS" rsync -avz --rsync-path="rsync" "${RASPI_USER}@${RASPI_IP}:/lib" rpi-sysroot
  sshpass -p "$RASPI_PASS" rsync -avz --exclude='/cups/backend/***' --rsync-path="rsync" "${RASPI_USER}@${RASPI_IP}:/usr/lib/" rpi-sysroot/usr/lib/

  #Sua chua symbol link, tranh bi loi link lien ket khi copy sysroot tu pi sang host
  wget -nc https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py
  chmod +x sysroot-relativelinks.py
  python3 sysroot-relativelinks.py rpi-sysroot
  if [ ! -f "$SYSROOT_AUXV_HEADER" ]; then
    echo "Sysroot thieu header bat buoc: $SYSROOT_AUXV_HEADER" >&2
    echo "Kiem tra tren Pi: sudo apt install -y libc6-dev" >&2
    exit 1
  fi
  touch rpi-sysroot/.sysroot-ready
fi

# Tao/cap nhat toolchain ke ca khi QtBase da duoc build tu lan chay truoc.
# qt.toolchain.cmake cua Qt se chain-load file nay khi build cac module bo sung.
cd "$HOME/$FOLDER_WORK/qt6/pi-build"
cat << 'EOF' > toolchain.cmake
cmake_minimum_required(VERSION 3.18)
include_guard(GLOBAL)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Tu vi tri <work>/qt6/pi-build/toolchain.cmake, quay lai <work> de tim
# sysroot. Khong dung FOLDER_WORK tu environment vi Qt Creator khong ke thua
# bien chi duoc export ben trong auto.sh.
get_filename_component(TARGET_SYSROOT "${CMAKE_CURRENT_LIST_DIR}/../../rpi-sysroot" ABSOLUTE)
get_filename_component(QT_TARGET_STAGING_DIR "${CMAKE_CURRENT_LIST_DIR}/../pi" ABSOLUTE)
set(TARGET_ARCHITECTURE aarch64-linux-gnu)
set(TARGET_LIBRARY_DIR ${TARGET_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE})
set(CMAKE_SYSROOT ${TARGET_SYSROOT})

set(ENV{PKG_CONFIG_PATH} $PKG_CONFIG_PATH:${CMAKE_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE}/pkgconfig)
set(ENV{PKG_CONFIG_LIBDIR} /usr/lib/pkgconfig:/usr/share/pkgconfig/:${TARGET_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE}/pkgconfig:${TARGET_SYSROOT}/usr/lib/pkgconfig)
set(ENV{PKG_CONFIG_SYSROOT_DIR} ${CMAKE_SYSROOT})

set(CMAKE_C_COMPILER /opt/cross-pi-gcc/bin/${TARGET_ARCHITECTURE}-gcc)
set(CMAKE_CXX_COMPILER /opt/cross-pi-gcc/bin/${TARGET_ARCHITECTURE}-g++)

# GCC nay cung co mot glibc bootstrap trong /opt/cross-pi-gcc. Neu khong uu
# tien startup objects cua Raspberry Pi, linker se tron crt1.o bootstrap voi
# libc cua sysroot va bao thieu __libc_csu_init/__libc_csu_fini.
# Khong them /usr/include cua host: --sysroot tu dong anh xa /usr/include dung.
set(CMAKE_C_FLAGS_INIT "-B${TARGET_LIBRARY_DIR}/")
set(CMAKE_CXX_FLAGS_INIT "-B${TARGET_LIBRARY_DIR}/")

set(QT_COMPILER_FLAGS "-march=armv8-a -B${TARGET_LIBRARY_DIR}/")
set(QT_COMPILER_FLAGS_RELEASE "-O2 -pipe")
set(QT_LINKER_FLAGS "-Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed -Wl,-rpath-link=${TARGET_SYSROOT}/usr/lib/${TARGET_ARCHITECTURE} -Wl,-rpath-link=${QT_TARGET_STAGING_DIR}/lib")

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

# Kiem tra toolchain truoc mot lan de tranh doi den khi configure module moi
# nhan duoc loi linker kho hieu.
TOOLCHAIN_SMOKE_DIR="$(mktemp -d)"
trap 'rm -rf "$TOOLCHAIN_SMOKE_DIR"' EXIT
printf '%s\n' 'int main(void) { return 0; }' > "$TOOLCHAIN_SMOKE_DIR/main.c"
/opt/cross-pi-gcc/bin/aarch64-linux-gnu-gcc \
  --sysroot="$HOME/$FOLDER_WORK/rpi-sysroot" \
  -B"$HOME/$FOLDER_WORK/rpi-sysroot/usr/lib/aarch64-linux-gnu/" \
  "$TOOLCHAIN_SMOKE_DIR/main.c" \
  -Wl,-rpath-link="$HOME/$FOLDER_WORK/rpi-sysroot/usr/lib/aarch64-linux-gnu" \
  -o "$TOOLCHAIN_SMOKE_DIR/main"
rm -rf "$TOOLCHAIN_SMOKE_DIR"
trap - EXIT

# Tao folder chua bien dich cheo cua Qt. Chi bo qua khi bo SDK target da du
# executable cau hinh va cac CMake package ma module Qt phia sau can dung.
QTBASE_PI_PREFIX="$HOME/$FOLDER_WORK/qt6/pi"
QTBASE_PI_CONFIG="$QTBASE_PI_PREFIX/lib/cmake/Qt6/Qt6Config.cmake"
QTBASE_PI_INTERNALS="$QTBASE_PI_PREFIX/lib/cmake/Qt6BuildInternals/Qt6BuildInternalsConfig.cmake"
if [ -x "$QTBASE_PI_PREFIX/bin/qt-configure-module" ] && \
   [ -f "$QTBASE_PI_CONFIG" ] && \
   [ -f "$QTBASE_PI_INTERNALS" ]; then
  echo "[SKIP] QtBase target cho Raspberry Pi da duoc cai day du."
else
  echo "[INFO] QtBase target chua du Qt6Config/BuildInternals, tien hanh build va cai lai."

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
  # Xoa cache configure loi va chi ro Qt target; QT_HOST_PATH chi dung cho tool host.
  rm -f CMakeCache.txt
  rm -rf CMakeFiles
  cmake "$QT_SHADERTOOLS_SOURCE" -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DINPUT_opengl=es2 \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF \
    -DQT_HOST_PATH="$QT_HOST_DIR" \
    -DQt6_DIR="$QT_PI_DIR/lib/cmake/Qt6" \
    -DQt6BuildInternals_DIR="$QT_PI_DIR/lib/cmake/Qt6BuildInternals" \
    -DCMAKE_PREFIX_PATH="$QT_PI_DIR" \
    -DCMAKE_STAGING_PREFIX="$QT_PI_DIR" \
    -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 \
    -DCMAKE_TOOLCHAIN_FILE="$HOME/$FOLDER_WORK/qt6/pi-build/toolchain.cmake" \
    -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 \
    -DQT_FEATURE_xcb=ON \
    -DFEATURE_xcb_xlib=ON \
    -DQT_FEATURE_xlib=ON
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

qt_declarative_is_installed() {
  local prefix="$1"
  local installation_kind="$2"
  local required_file
  local required_files=(
    "lib/libQt6Qml.so.${QT_VERSION}"
    "lib/libQt6Quick.so.${QT_VERSION}"
    "lib/cmake/Qt6Qml/Qt6QmlConfig.cmake"
    "lib/cmake/Qt6Quick/Qt6QuickConfig.cmake"
  )

  # Cac tool nay chi chay tren host; ban target dung tool tu QT_HOST_PATH.
  if [ "$installation_kind" = "host" ]; then
    required_files+=("libexec/qmlcachegen" "libexec/qmltyperegistrar")
  fi

  for required_file in "${required_files[@]}"; do
    if [ ! -e "$prefix/$required_file" ]; then
      return 1
    fi
  done
}

cd "$QT_SRC_DIR"
wget -nc "https://download.qt.io/official_releases/qt/6.5/${QT_VERSION}/submodules/${QT_DECLARATIVE_ARCHIVE}"
if [ ! -d "$QT_DECLARATIVE_SOURCE" ]; then
  tar xf "$QT_DECLARATIVE_ARCHIVE"
fi

mkdir -p "$QT_DECLARATIVE_HOST_BUILD"
if [ -f "$QT_DECLARATIVE_HOST_BUILD/.install-complete" ] || \
   qt_declarative_is_installed "$QT_HOST_DIR" host; then
  echo "[SKIP] Qt Declarative cho host da duoc cai."
  # Chuyen doi ban cai cu, truoc khi script su dung marker.
  touch "$QT_DECLARATIVE_HOST_BUILD/.install-complete"
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
if [ -f "$QT_DECLARATIVE_PI_BUILD/.install-complete" ] || \
   qt_declarative_is_installed "$QT_PI_DIR" target; then
  echo "[SKIP] Qt Declarative cho Raspberry Pi da duoc cai."
  touch "$QT_DECLARATIVE_PI_BUILD/.install-complete"
else
  cd "$QT_DECLARATIVE_PI_BUILD"
  rm -f CMakeCache.txt
  cmake "$QT_DECLARATIVE_SOURCE" -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DINPUT_opengl=es2 \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF \
    -DQT_HOST_PATH="$HOME/$FOLDER_WORK/qt6/host" \
    -DCMAKE_STAGING_PREFIX="$HOME/$FOLDER_WORK/qt6/pi" \
    -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 \
    -DCMAKE_TOOLCHAIN_FILE="$HOME/$FOLDER_WORK/qt6/pi-build/toolchain.cmake" \
    -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 \
    -DQT_FEATURE_xcb=ON \
    -DFEATURE_xcb_xlib=ON \
    -DQT_FEATURE_xlib=ON
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_DECLARATIVE_PI_BUILD/.install-complete"
fi
#================================================================================================================

#=============================================CAI QT HTTP SERVER=================================================
QT_HTTPSERVER_ARCHIVE="qthttpserver-everywhere-src-${QT_VERSION}.tar.xz"
QT_HTTPSERVER_SOURCE="$QT_SRC_DIR/qthttpserver-everywhere-src-${QT_VERSION}"
QT_HTTPSERVER_HOST_BUILD="$HOME/$FOLDER_WORK/qt6/host-build-qthttpserver"
QT_HTTPSERVER_PI_BUILD="$HOME/$FOLDER_WORK/qt6/pi-build-qthttpserver"

download_qt_module_archive() {
  local archive="$1"
  local url="https://download.qt.io/official_releases/qt/6.5/${QT_VERSION}/submodules/${archive}"

  if [ -f "$archive" ] && tar tf "$archive" >/dev/null 2>&1; then
    echo "[SKIP] Archive hop le da ton tai: $archive"
    return
  fi

  rm -f "${archive}.part"
  wget -O "${archive}.part" "$url"
  tar tf "${archive}.part" >/dev/null
  mv -f "${archive}.part" "$archive"
}

qt_httpserver_is_installed() {
  local prefix="$1"
  [ -f "$prefix/lib/cmake/Qt6HttpServer/Qt6HttpServerConfig.cmake" ] && \
    [ -e "$prefix/lib/libQt6HttpServer.so.${QT_VERSION}" ]
}

cd "$QT_SRC_DIR"
download_qt_module_archive "$QT_HTTPSERVER_ARCHIVE"
if [ ! -f "$QT_HTTPSERVER_SOURCE/.extract-complete" ]; then
  tar xf "$QT_HTTPSERVER_ARCHIVE"
  touch "$QT_HTTPSERVER_SOURCE/.extract-complete"
fi

mkdir -p "$QT_HTTPSERVER_HOST_BUILD"
if [ -f "$QT_HTTPSERVER_HOST_BUILD/.install-complete" ] || \
   qt_httpserver_is_installed "$QT_HOST_DIR"; then
  echo "[SKIP] Qt HTTP Server cho host da duoc cai."
  touch "$QT_HTTPSERVER_HOST_BUILD/.install-complete"
else
  cd "$QT_HTTPSERVER_HOST_BUILD"
  "$QT_HOST_DIR/bin/qt-configure-module" "$QT_HTTPSERVER_SOURCE" -- \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_HTTPSERVER_HOST_BUILD/.install-complete"
fi

mkdir -p "$QT_HTTPSERVER_PI_BUILD"
if [ -f "$QT_HTTPSERVER_PI_BUILD/.install-complete" ] || \
   qt_httpserver_is_installed "$QT_PI_DIR"; then
  echo "[SKIP] Qt HTTP Server cho Raspberry Pi da duoc cai."
  touch "$QT_HTTPSERVER_PI_BUILD/.install-complete"
else
  cd "$QT_HTTPSERVER_PI_BUILD"
  rm -f CMakeCache.txt
  cmake "$QT_HTTPSERVER_SOURCE" -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DINPUT_opengl=es2 \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF \
    -DQT_HOST_PATH="$HOME/$FOLDER_WORK/qt6/host" \
    -DCMAKE_STAGING_PREFIX="$HOME/$FOLDER_WORK/qt6/pi" \
    -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 \
    -DCMAKE_TOOLCHAIN_FILE="$HOME/$FOLDER_WORK/qt6/pi-build/toolchain.cmake" \
    -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 \
    -DQT_FEATURE_xcb=ON \
    -DFEATURE_xcb_xlib=ON \
    -DQT_FEATURE_xlib=ON
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_HTTPSERVER_PI_BUILD/.install-complete"
fi
#================================================================================================================

#=============================================CAI QT CHARTS======================================================
QT_CHARTS_ARCHIVE="qtcharts-everywhere-src-${QT_VERSION}.tar.xz"
QT_CHARTS_SOURCE="$QT_SRC_DIR/qtcharts-everywhere-src-${QT_VERSION}"
QT_CHARTS_HOST_BUILD="$HOME/$FOLDER_WORK/qt6/host-build-qtcharts"
QT_CHARTS_PI_BUILD="$HOME/$FOLDER_WORK/qt6/pi-build-qtcharts"

qt_charts_is_installed() {
  local prefix="$1"
  [ -f "$prefix/lib/cmake/Qt6Charts/Qt6ChartsConfig.cmake" ] && \
    [ -e "$prefix/lib/libQt6Charts.so.${QT_VERSION}" ]
}

cd "$QT_SRC_DIR"
download_qt_module_archive "$QT_CHARTS_ARCHIVE"
if [ ! -f "$QT_CHARTS_SOURCE/.extract-complete" ]; then
  tar xf "$QT_CHARTS_ARCHIVE"
  touch "$QT_CHARTS_SOURCE/.extract-complete"
fi

mkdir -p "$QT_CHARTS_HOST_BUILD"
if [ -f "$QT_CHARTS_HOST_BUILD/.install-complete" ] || \
   qt_charts_is_installed "$QT_HOST_DIR"; then
  echo "[SKIP] Qt Charts cho host da duoc cai."
  touch "$QT_CHARTS_HOST_BUILD/.install-complete"
else
  cd "$QT_CHARTS_HOST_BUILD"
  "$QT_HOST_DIR/bin/qt-configure-module" "$QT_CHARTS_SOURCE" -- \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_CHARTS_HOST_BUILD/.install-complete"
fi

mkdir -p "$QT_CHARTS_PI_BUILD"
if [ -f "$QT_CHARTS_PI_BUILD/.install-complete" ] || \
   qt_charts_is_installed "$QT_PI_DIR"; then
  echo "[SKIP] Qt Charts cho Raspberry Pi da duoc cai."
  touch "$QT_CHARTS_PI_BUILD/.install-complete"
else
  cd "$QT_CHARTS_PI_BUILD"
  rm -f CMakeCache.txt
  cmake "$QT_CHARTS_SOURCE" -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DINPUT_opengl=es2 \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF \
    -DQT_HOST_PATH="$HOME/$FOLDER_WORK/qt6/host" \
    -DCMAKE_STAGING_PREFIX="$HOME/$FOLDER_WORK/qt6/pi" \
    -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 \
    -DCMAKE_TOOLCHAIN_FILE="$HOME/$FOLDER_WORK/qt6/pi-build/toolchain.cmake" \
    -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 \
    -DQT_FEATURE_xcb=ON \
    -DFEATURE_xcb_xlib=ON \
    -DQT_FEATURE_xlib=ON
  cmake --build . --parallel 8
  cmake --install .
  touch "$QT_CHARTS_PI_BUILD/.install-complete"
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
  rm -f CMakeCache.txt
  cmake "$QT_SERIALPORT_SOURCE" -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DINPUT_opengl=es2 \
    -DQT_BUILD_EXAMPLES=OFF \
    -DQT_BUILD_TESTS=OFF \
    -DQT_HOST_PATH="$HOME/$FOLDER_WORK/qt6/host" \
    -DCMAKE_STAGING_PREFIX="$HOME/$FOLDER_WORK/qt6/pi" \
    -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 \
    -DCMAKE_TOOLCHAIN_FILE="$HOME/$FOLDER_WORK/qt6/pi-build/toolchain.cmake" \
    -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 \
    -DQT_FEATURE_xcb=ON \
    -DFEATURE_xcb_xlib=ON \
    -DQT_FEATURE_xlib=ON
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

qt_creator_is_installed() {
  local package_status
  local installed_version

  package_status="$(dpkg-query -W -f='${db:Status-Abbrev}' qtcreator 2>/dev/null)" || return 1
  installed_version="$(dpkg-query -W -f='${Version}' qtcreator 2>/dev/null)" || return 1

  [ "$package_status" = "ii " ] && \
    [ "${installed_version%%-*}" = "$QT_CREATOR_VERSION" ] && \
    [ -x /opt/qt-creator/bin/qtcreator ]
}

mkdir -p "$QT_CREATOR_DIR"
cd "$QT_CREATOR_DIR"

if qt_creator_is_installed; then
  echo "[SKIP] Qt Creator ${QT_CREATOR_VERSION} da duoc cai."
  # Tao marker cho ban da duoc cai truoc khi script co co che danh dau.
  touch "$QT_CREATOR_MARKER"
else
  wget -nc "$QT_CREATOR_URL"
  printf '%s\n' "$HOST_PASS" | sudo -S -p '' apt install -y "./$QT_CREATOR_DEB"
  touch "$QT_CREATOR_MARKER"
fi
#================================================================================================================
