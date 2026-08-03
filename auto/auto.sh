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
  # Loai bo CRLF va UTF-8 BOM neu config duoc tao/sua tren Windows.
  rawline="${rawline%$'\r'}"
  rawline="${rawline#$'\xEF\xBB\xBF'}"
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

if [ "${#lines[@]}" -lt 5 ]; then
  echo "config.txt phai co it nhat 5 gia tri: host user/pass, Pi user/pass va Pi IP." >&2
  exit 1
fi

if [[ ! "$HOST_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Username may host trong config.txt khong hop le: chi dung chu thuong, so, _ hoac -." >&2
  exit 1
fi

if [[ ! "$RASPI_USER" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Username Raspberry Pi trong config.txt khong hop le: chi dung chu thuong, so, _ hoac -." >&2
  exit 1
fi

is_valid_ipv4() {
  local ip="$1"
  local octet
  local -a octets
  IFS='.' read -r -a octets <<< "$ip"
  [ "${#octets[@]}" -eq 4 ] || return 1
  for octet in "${octets[@]}"; do
    [[ "$octet" =~ ^[0-9]{1,3}$ ]] || return 1
    (( 10#$octet <= 255 )) || return 1
  done
}

if ! is_valid_ipv4 "$RASPI_IP"; then
  echo "Dia chi IP Raspberry Pi trong config.txt khong hop le: '$RASPI_IP'." >&2
  exit 1
fi

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
# Luon cap nhat va cai dependency tren Raspberry Pi truoc khi build.
sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
  "printf '%s\n' '$RASPI_PASS' | sudo -S -p '' apt update && printf '%s\n' '$RASPI_PASS' | sudo -S -p '' apt full-upgrade -y"

PKGS="$(tr -d '\r' < dep_list_raspi.txt | tr '\n' ' ')"
sshpass -p "$RASPI_PASS" ssh -t -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" \
  "printf '%s\n' \"$RASPI_PASS\" | sudo -S -p '' apt install -y $PKGS"

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

sed -i '1i#ifndef PATH_MAX\n#define PATH_MAX 4096\n#endif' ~/Qt6Cross/gcc_all/gcc-10.3.0/libsanitizer/asan/asan_linux.cpp


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
  # Build host trong subshell sach. Khi ket thuc, moi bien moi truong cu tu dong
  # duoc khoi phuc trong shell chinh de cac buoc cross-compile phia sau su dung.
  (
    unset CMAKE_PREFIX_PATH CMAKE_TOOLCHAIN_FILE CMAKE_SYSROOT CMAKE_LIBRARY_PATH
    unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR
    unset LIBRARY_PATH CPATH CPLUS_INCLUDE_PATH

    QT_HOST_BUILD_DIR="$HOME/Qt6Cross/qt6/host-build"
    if [ "$QT_HOST_BUILD_DIR" != "$HOME/Qt6Cross/qt6/host-build" ]; then
      echo "Tu choi xoa host-build khong dung: $QT_HOST_BUILD_DIR" >&2
      exit 1
    fi
    rm -rf -- "$QT_HOST_BUILD_DIR"
    mkdir -p "$QT_HOST_BUILD_DIR"

    cmake \
      -S "$HOME/Qt6Cross/qt6/src/qtbase-everywhere-src-6.5.1" \
      -B "$QT_HOST_BUILD_DIR" \
      -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DQT_BUILD_EXAMPLES=OFF \
      -DQT_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX="$HOME/Qt6Cross/qt6/host"

    if grep -qi 'rpi-sysroot' "$QT_HOST_BUILD_DIR/CMakeCache.txt"; then
      echo "Qt host cache van chua duong dan rpi-sysroot; dung build de tranh tron thu vien ARM." >&2
      grep -i 'rpi-sysroot' "$QT_HOST_BUILD_DIR/CMakeCache.txt" >&2
      exit 1
    fi

    cmake --build "$QT_HOST_BUILD_DIR" --parallel 8
    cmake --install "$QT_HOST_BUILD_DIR"
  )
fi



#Tao folder chua sysroot cua raspi
cd ~/$FOLDER_WORK
SYSROOT_AUXV_HEADER="$HOME/$FOLDER_WORK/rpi-sysroot/usr/include/aarch64-linux-gnu/bits/auxv.h"
mkdir -p rpi-sysroot/usr/lib

PI_ARCH="$(sshpass -p "$RASPI_PASS" ssh -o StrictHostKeyChecking=no "${RASPI_USER}@${RASPI_IP}" "dpkg --print-architecture")"
if [ "$PI_ARCH" != "arm64" ]; then
  echo "Raspberry Pi userland phai la arm64, nhung hien tai la: $PI_ARCH" >&2
  exit 1
fi

# Luon dong bo lai sysroot tu Raspberry Pi moi lan chay script.
sshpass -p "$RASPI_PASS" rsync -avz --rsync-path="rsync" "${RASPI_USER}@${RASPI_IP}:/usr/include" rpi-sysroot/usr
sshpass -p "$RASPI_PASS" rsync -avz --rsync-path="rsync" "${RASPI_USER}@${RASPI_IP}:/lib" rpi-sysroot
sshpass -p "$RASPI_PASS" rsync -avz --exclude='/cups/backend/***' --rsync-path="rsync" "${RASPI_USER}@${RASPI_IP}:/usr/lib/" rpi-sysroot/usr/lib/

# Sua chua symbolic link sau moi lan cap nhat sysroot.
wget -nc https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py
chmod +x sysroot-relativelinks.py
python3 sysroot-relativelinks.py rpi-sysroot
if [ ! -f "$SYSROOT_AUXV_HEADER" ]; then
  echo "Sysroot thieu header bat buoc: $SYSROOT_AUXV_HEADER" >&2
  echo "Kiem tra tren Pi: sudo apt install -y libc6-dev" >&2
  exit 1
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
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)
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

cd $HOME/Qt6Cross/qt6/pi-build
cmake ../src/qtbase-everywhere-src-6.5.1/ -GNinja -DCMAKE_BUILD_TYPE=Release -DINPUT_opengl=es2 -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_HOST_PATH=$HOME/Qt6Cross/qt6/host -DCMAKE_STAGING_PREFIX=$HOME/Qt6Cross/qt6/pi -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 -DCMAKE_TOOLCHAIN_FILE=$HOME/Qt6Cross/qt6/pi-build/toolchain.cmake -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 -DQT_FEATURE_xcb=ON -DFEATURE_xcb_xlib=ON -DQT_FEATURE_xlib=ON
cmake --build . --parallel 8
cmake --install .
fi

sshpass -p "$RASPI_PASS" rsync -avz \
  "$HOME/$FOLDER_WORK/qt6/pi/" "${RASPI_USER}@${RASPI_IP}:/usr/local/qt6/"
#================================================================================================================

#=============================================CAI CAC QT MODULE==================================================
QT_VERSION="6.5.1"
QT_DOWNLOAD_BASE="https://download.qt.io/official_releases/qt/6.5/${QT_VERSION}/submodules"
QT_SRC_DIR="$HOME/$FOLDER_WORK/qt6/src"
QT_HOST_DIR="$HOME/$FOLDER_WORK/qt6/host"
QT_PI_DIR="$HOME/$FOLDER_WORK/qt6/pi"
QT_PI_BUILD="$HOME/$FOLDER_WORK/qt6/pi-build"
QT_PI_TOOLCHAIN="$QT_PI_BUILD/toolchain.cmake"
QT_MODULE_MARKER_DIR="$HOME/$FOLDER_WORK/qt6/module-markers"
mkdir -p "$QT_MODULE_MARKER_DIR"

qt_module_is_installed() {
  local prefix="$1"
  local cmake_config="$2"
  local library_name="$3"

  [ -f "$prefix/$cmake_config" ] && \
    compgen -G "$prefix/lib/${library_name}.so*" >/dev/null
}

prepare_shared_qt_pi_build() {
  local actual_build_dir
  local expected_build_dir="$(cd "$HOME/$FOLDER_WORK/qt6" && pwd -P)/pi-build"

  mkdir -p "$QT_PI_BUILD"
  actual_build_dir="$(cd "$QT_PI_BUILD" && pwd -P)"
  if [ "$actual_build_dir" != "$expected_build_dir" ]; then
    echo "Tu choi don build directory khong dung: $actual_build_dir" >&2
    exit 1
  fi
  if [ ! -f "$QT_PI_TOOLCHAIN" ]; then
    echo "Khong tim thay toolchain dung chung: $QT_PI_TOOLCHAIN" >&2
    exit 1
  fi

  # Tai lieu dung rm -rf *; script giu toolchain.cmake va xoa moi output module cu.
  find "$QT_PI_BUILD" -mindepth 1 -maxdepth 1 ! -name toolchain.cmake -exec rm -rf -- {} +
  cd "$QT_PI_BUILD"
}

build_qt_module() {
  local module_key="$1"
  local module_title="$2"
  local cmake_config="$3"
  local library_name="$4"
  local archive="${module_key}-everywhere-src-${QT_VERSION}.tar.xz"
  local source_dir="$QT_SRC_DIR/${module_key}-everywhere-src-${QT_VERSION}"
  local host_build="$HOME/$FOLDER_WORK/qt6/host-build-${module_key}"
  local host_marker="$QT_MODULE_MARKER_DIR/${module_key}-host.complete"
  local pi_marker="$QT_MODULE_MARKER_DIR/${module_key}-pi.complete"

  cd "$QT_SRC_DIR"
  if [ ! -f "$archive" ]; then
    wget "$QT_DOWNLOAD_BASE/$archive"
  else
    echo "[SKIP] Archive da ton tai: $archive"
  fi
  if [ ! -d "$source_dir" ]; then
    tar xf "$archive"
  else
    echo "[SKIP] Source da ton tai: $source_dir"
  fi

  # Qt Declarative 6.5.1 bundled MASM dung PATH_MAX nhung thieu limits.h
  # voi sysroot Raspberry Pi. Patch idempotent, khong chen lai neu da co.
  if [ "$module_key" = "qtdeclarative" ]; then
    local os_allocator="$source_dir/src/3rdparty/masm/wtf/OSAllocatorPosix.cpp"
    if [ ! -f "$os_allocator" ]; then
      echo "Khong tim thay source can patch: $os_allocator" >&2
      exit 1
    fi
    if ! grep -Fq '#include <limits.h>' "$os_allocator"; then
      sed -i '1i#include <limits.h>' "$os_allocator"
      echo "[PATCH] Da them limits.h cho PATH_MAX trong Qt Declarative."
    fi
  fi

  if qt_module_is_installed "$QT_HOST_DIR" "$cmake_config" "$library_name"; then
    echo "[SKIP] $module_title cho host da duoc cai."
    touch "$host_marker"
  else
    mkdir -p "$host_build"
    cd "$host_build"
    rm -f CMakeCache.txt
    rm -rf CMakeFiles
    cmake "$source_dir" -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DQT_BUILD_EXAMPLES=OFF \
      -DQT_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX="$QT_HOST_DIR" \
      -DCMAKE_PREFIX_PATH="$QT_HOST_DIR" \
      -DQt6_DIR="$QT_HOST_DIR/lib/cmake/Qt6" \
      -DQt6BuildInternals_DIR="$QT_HOST_DIR/lib/cmake/Qt6BuildInternals"
    cmake --build . --parallel 8
    cmake --install .
    touch "$host_marker"
  fi

  if qt_module_is_installed "$QT_PI_DIR" "$cmake_config" "$library_name"; then
    echo "[SKIP] $module_title cho Raspberry Pi da duoc cai."
    touch "$pi_marker"
  else
    prepare_shared_qt_pi_build
    cmake "$source_dir" -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DINPUT_opengl=es2 \
      -DQT_BUILD_EXAMPLES=OFF \
      -DQT_BUILD_TESTS=OFF \
      -DQT_HOST_PATH="$QT_HOST_DIR" \
      -DCMAKE_PREFIX_PATH="$QT_PI_DIR" \
      -DQt6_DIR="$QT_PI_DIR/lib/cmake/Qt6" \
      -DQt6BuildInternals_DIR="$QT_PI_DIR/lib/cmake/Qt6BuildInternals" \
      -DCMAKE_STAGING_PREFIX="$QT_PI_DIR" \
      -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 \
      -DCMAKE_TOOLCHAIN_FILE="$QT_PI_TOOLCHAIN" \
      -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 \
      -DQT_FEATURE_xcb=ON \
      -DFEATURE_xcb_xlib=ON \
      -DQT_FEATURE_xlib=ON
    cmake --build . --parallel 8
    cmake --install .

    sshpass -p "$RASPI_PASS" rsync -avz \
      "$QT_PI_DIR/" "${RASPI_USER}@${RASPI_IP}:/usr/local/qt6/"
    touch "$pi_marker"
    echo "[DONE] $module_title da build, install va dong bo sang Raspberry Pi."
  fi
}

# Tat ca module cung mot flow; chi thay ten source, package CMake va library kiem tra.
build_qt_module "qtshadertools" "Qt Shader Tools" \
  "lib/cmake/Qt6ShaderTools/Qt6ShaderToolsConfig.cmake" "libQt6ShaderTools"
build_qt_module "qtdeclarative" "Qt Declarative" \
  "lib/cmake/Qt6Qml/Qt6QmlConfig.cmake" "libQt6Qml"
build_qt_module "qthttpserver" "Qt HTTP Server" \
  "lib/cmake/Qt6HttpServer/Qt6HttpServerConfig.cmake" "libQt6HttpServer"
build_qt_module "qtcharts" "Qt Charts" \
  "lib/cmake/Qt6Charts/Qt6ChartsConfig.cmake" "libQt6Charts"
build_qt_module "qtserialport" "Qt Serial Port" \
  "lib/cmake/Qt6SerialPort/Qt6SerialPortConfig.cmake" "libQt6SerialPort"
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
