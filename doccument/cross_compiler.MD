

                          QT 6.5.1 CROSS COMPILER IN UBUNTU -> RASPBERY PI 4


* CÁC FILE CẦN THIẾT CÓ THỂ DÙNG LUÔN.

    https://drive.google.com/drive/folders/1INfJcckDI_olr4NDbNYfu6JdJKIJMWz6?usp=sharing

I. CÁC LỆNH CẦN THIẾT TRÊN MÁY BULD (RASPBERY PI 4) 
    
    - Cập nhật cho các files cần thiết:

        sudo apt update
        sudo apt upgrade  

    - Cài các packet liên quan

        sudo apt-get install libboost-all-dev libudev-dev libinput-dev libts-dev libmtdev-dev libjpeg-dev libfontconfig1-dev libssl-dev libdbus-1-dev libglib2.0-dev libxkbcommon-dev libegl1-mesa-dev libgbm-dev libgles2-mesa-dev mesa-common-dev libasound2-dev libpulse-dev gstreamer1.0-omx libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev  gstreamer1.0-alsa libvpx-dev libsrtp2-dev libsnappy-dev libnss3-dev "^libxcb.*" flex bison libxslt-dev ruby gperf libbz2-dev libcups2-dev libatkmm-1.6-dev libxi6 libxcomposite1 libfreetype6-dev libicu-dev libsqlite3-dev libxslt1-dev 

        sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev libx11-dev freetds-dev libsqlite3-dev libpq-dev libiodbc2-dev firebird-dev libxext-dev libxcb1 libxcb1-dev libx11-xcb1 libx11-xcb-dev libxcb-keysyms1 libxcb-keysyms1-dev libxcb-image0 libxcb-image0-dev libxcb-shm0 libxcb-shm0-dev libxcb-icccm4 libxcb-icccm4-dev libxcb-sync1 libxcb-sync-dev libxcb-render-util0 libxcb-render-util0-dev libxcb-xfixes0-dev libxrender-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-glx0-dev libxi-dev libdrm-dev libxcb-xinerama0 libxcb-xinerama0-dev libatspi2.0-dev libxcursor-dev libxcomposite-dev libxdamage-dev libxss-dev libxtst-dev libpci-dev libcap-dev libxrandr-dev libdirectfb-dev libaudio-dev libxkbcommon-x11-dev gdbserver

    - Tạo folder chứ file bin sau khi build của Qt6.5.1, cấp quyền cho toàn bộ đối tượng có thể truy cập:

        sudo mkdir /usr/local/qt6
        sudo chmod 777 /usr/local/bin

    - Thêm đường dẫn đến thư viện lib sau này để link khi chạy chương trình

        echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/qt6/lib/' >> ~/.bashrc
        source ~/.bashrc

II. CÁC LỆNH CẦN THIẾT CHO MÁY HOST (UBUNTU 22.04.5):

    - Cập nhật cho các files cần thiết:

        sudo apt update
        sudo apt upgrade  
    
    - Cài các gói cần thiết cho host 

        sudo apt-get install make build-essential libclang-dev ninja-build gcc git bison python3 gperf pkg-config libfontconfig1-dev libfreetype6-dev libx11-dev libx11-xcb-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libatspi2.0-dev libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev build-essential gawk git texinfo bison file wget libssl-dev gdbserver gdb-multiarch libxcb-cursor-dev

    - Tạo thư mục để chuẩn bị cho quá trình cross-compiler 

        cd ~
        mkdir Qt6Cross 

    - Tải xuống và cài đặt Cmake (quá trình tải, buid, intall rất lâu, nên kiên trì đợi)

        cd ~/Qt6Cross
        git clone https://github.com/Kitware/CMake.git
        cd CMake
        ./bootstrap && make -j8&& sudo make install

    1.1: Tải tools biên dịch chéo sử dụng GCC

        cd ~/Qt6Cross
        mkdir gcc_all && cd gcc_all

        + Lưu ý làm đến bước này nếu bạn đã tải các file (binutils, glibc, gcc, linux) thì cho các thư mục đó vào thư mục  gcc_all
            nếu bạn không làm theo cách đó thì tải ở đây cũng được, nhưng chú ý nếu tải fail thì cần xóa thư mục đó đi tạo lại. tránh rắc rối không cần thiết, tại server của các gói này đặt ở nước ngoài.

            wget https://ftpmirror.gnu.org/binutils/binutils-2.35.2.tar.bz2
            wget https://ftpmirror.gnu.org/glibc/glibc-2.31.tar.bz2
            wget https://ftpmirror.gnu.org/gcc/gcc-10.3.0/gcc-10.3.0.tar.gz
            git clone --depth=1 https://github.com/raspberrypi/linux

        + Giải nén và auto config 

            tar xf binutils-2.35.2.tar.bz2
            tar xf glibc-2.31.tar.bz2
            tar xf gcc-10.3.0.tar.gz
            rm *.tar.*
            cd gcc-10.3.0
            contrib/download_prerequisites

        + Tạo folder cài đặt chứa trình biên dịch chéo

            sudo mkdir -p /opt/cross-pi-gcc
            sudo chown $USER /opt/cross-pi-gcc
            export PATH=/opt/cross-pi-gcc/bin:$PATH

        + Sau bước này, thư mục /opt/cross-pi-gcc/aarch64-linux-gnu/include sẽ có đầy đủ header của kernel.

            cd ~/Qt6Cross/gcc_all
            cd linux
            KERNEL=kernel7
            make ARCH=arm64 INSTALL_HDR_PATH=/opt/cross-pi-gcc/aarch64-linux-gnu headers_install

        + Build và cài đặt binutils cho cross-compiler


            cd ~/Qt6Cross/gcc_all
            mkdir build-binutils && cd build-binutils
            ../binutils-2.35.2/configure --prefix=/opt/cross-pi-gcc --target=aarch64-linux-gnu --with-arch=armv8 --disable-multilib
            make -j 8
            make install

        + Trên một số hệ thống (hoặc một số phiên bản glibc), PATH_MAX chưa được định nghĩa ở thời điểm GCC đọc file này.
        Nếu không định nghĩa, khi build GCC bạn sẽ gặp lỗi kiểu: "asan_linux.cpp: error: 'PATH_MAX' was not declared in this scope"

            sed -i '1i#ifndef PATH_MAX\n#define PATH_MAX 4096\n#endif' ~/Qt6Cross/gcc_all/gcc-10.3.0/libsanitizer/asan/asan_linux.cpp
        
        + Build GCC cross-compiler chính

            cd ~/Qt6Cross/gcc_all
            mkdir build-gcc && cd build-gcc
            ../gcc-10.3.0/configure --prefix=/opt/cross-pi-gcc --target=aarch64-linux-gnu --enable-languages=c,c++ --disable-multilib
            make -j8 all-gcc
            make install-gcc
        
        + build và cài đặt glibc cho cross-compiler, cung cấp thư viện runtime C chuẩn để compiler có thể tạo binary chạy trên Raspberry Pi.


            cd ~/Qt6Cross/gcc_all
            mkdir build-glibc && cd build-glibc
            ../glibc-2.31/configure --prefix=/opt/cross-pi-gcc/aarch64-linux-gnu --build=$MACHTYPE --host=aarch64-linux-gnu --target=aarch64-linux-gnu --with-headers=/opt/cross-pi-gcc/aarch64-linux-gnu/include --disable-multilib libc_cv_forced_unwind=yes
            make install-bootstrap-headers=yes install-headers
            make -j8 csu/subdir_lib
            install csu/crt1.o csu/crti.o csu/crtn.o /opt/cross-pi-gcc/aarch64-linux-gnu/lib
            aarch64-linux-gnu-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o /opt/cross-pi-gcc/aarch64-linux-gnu/lib/libc.so
            touch /opt/cross-pi-gcc/aarch64-linux-gnu/include/gnu/stubs.h

        + Build thư viện runtime libgcc cho cross-compiler

            cd ~/Qt6Cross/gcc_all/build-gcc
            make -j8 all-target-libgcc
            make install-target-libgcc


        + Build glibc đầy đủ cho cross-compiler

            cd ~/Qt6Cross/gcc_all/build-glibc
            make -j8
            make install
        
        + Build và cài đặt GCC hoàn chỉnh sau khi đã chuẩn bị glibc và libgcc

            cd ~/Qt6Cross/gcc_all/build-gcc
            make -j8
            make install

    1.2 Build lại Qt6.5.1
        - Lưu ý từ đoạn này có những file rất nặng nên cần mạng khỏe và chờ lâu, nếu lỗi phải xóa thưu mục đó đi và cài lại.

        cd ~/Qt6Cross
        mkdir qt6 qt6/host qt6/pi qt6/host-build qt6/pi-build qt6/src

        cd ~/Qt6Cross/qt6/src
        wget https://download.qt.io/official_releases/qt/6.5/6.5.1/submodules/qtbase-everywhere-src-6.5.1.tar.xz
        tar xf qtbase-everywhere-src-6.5.1.tar.xz

        + Build Qt6 cho Host

            cd $HOME/Qt6Cross/qt6/host-build/
            cmake ../src/qtbase-everywhere-src-6.5.1/ -GNinja -DCMAKE_BUILD_TYPE=Release -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$HOME/Qt6Cross/qt6/host
            cmake --build . --parallel 8
            cmake --install .

        + Build Qt6 cho RPI
            - lưu ý đoạn này thay đúng địa chỉ raspberry pi 4 và username của pi, đọa này nếu lỗi thì bạn xóa đoạn "sudo rsync" bỏ sudo đi để nguyên "rsync" như vậy thôi.
            
                cd ~/Qt6Cross
                mkdir rpi-sysroot rpi-sysroot/usr 

                cd ~/Qt6Cross
                rsync -avz --rsync-path="sudo rsync" <username raspbery của ban >@<địa chỉ ip của raspberry pi>:/usr/include rpi-sysroot/usr
                rsync -avz --rsync-path="sudo rsync" <username raspbery của ban >@<địa chỉ ip của raspberry pi>:/lib rpi-sysroot
                rsync -avz --rsync-path="sudo rsync" <username raspbery của ban >@<địa chỉ ip của raspberry pi>:/usr/lib rpi-sysroot/usr

                wget https://raw.githubusercontent.com/riscv/riscv-poky/master/scripts/sysroot-relativelinks.py
                chmod +x sysroot-relativelinks.py 
                python3 sysroot-relativelinks.py rpi-sysroot

        + Tạo file cmake để cấu hình biên dịch Qt6 cho RPI

            cd $HOME/Qt6Cross/qt6/pi-build

            cat << 'EOF' > toolchain.cmake
            cmake_minimum_required(VERSION 3.18)
            include_guard(GLOBAL)

            set(CMAKE_SYSTEM_NAME Linux)
            set(CMAKE_SYSTEM_PROCESSOR arm)

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
    
    + Biên dịch Qt6 cho RPI

        cd $HOME/Qt6Cross/qt6/pi-build
        cmake ../src/qtbase-everywhere-src-6.5.1/ -GNinja -DCMAKE_BUILD_TYPE=Release -DINPUT_opengl=es2 -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_HOST_PATH=$HOME/Qt6Cross/qt6/host -DCMAKE_STAGING_PREFIX=$HOME/Qt6Cross/qt6/pi -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 -DCMAKE_TOOLCHAIN_FILE=$HOME/Qt6Cross/qt6/pi-build/toolchain.cmake -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 -DQT_FEATURE_xcb=ON -DFEATURE_xcb_xlib=ON -DQT_FEATURE_xlib=ON
        cmake --build . --parallel 8
        cmake --install .

    + Send binaries sang cho RPI
        - lưu ý lỗi liên quan đến quyền thì sửa bỏ sudo đi 
        rsync -avz --rsync-path="sudo rsync" $HOME/Qt6Cross/qt6/pi/* <username>@<Địa chỉ raspbery pi của bạn>:/usr/local/qt6

    

III. CÀI THÊM CÁC LIB KHÁC SAU NÀY. 

    - Giả sử sau này bạn không chỉ cần thêm lib Qtbase mà cần thêm qtdeclarative và qtshadertools
    - các lib đó bạn có thể xem trên https://download.qt.io/official_releases/qt/6.5/6.5.1/submodules/ và nhớ là file.tar.xz nhé!

    + Bạn lại phải vào đây là quá trình làm lại cho host

        cd ~/Qt6Cross/qt6/src
        wget https://download.qt.io/official_releases/qt/6.5/6.5.1/submodules/<thay bằng cái lib của bạn>
        tar xf <thay thành lib của bạn>

        cd .. 
        mkdir <thay bằng tên lib của bạn định cài> VD: host-build-declarative

        cd <thay bằng tên lib của bạn định cài> VD: host-build-declarative

        - chú ý thay đổi đúng

        cd $HOME/Qt6Cross/qt6/host-build/
            cmake ../src/<thay bằng tên files sau khi đã giải nén vd: qtdeclarative-everywhere-src-6.5.1>/ -GNinja -DCMAKE_BUILD_TYPE=Release -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$HOME/Qt6Cross/qt6/host
            cmake --build . --parallel 8
            cmake --install .

    + đây là quá trình làm lại cho raspbery pi 

        cd $HOME/Qt6Cross/qt6/pi-build 

        rm -rf * 

        cat << 'EOF' > toolchain.cmake
            cmake_minimum_required(VERSION 3.18)
            include_guard(GLOBAL)

            set(CMAKE_SYSTEM_NAME Linux)
            set(CMAKE_SYSTEM_PROCESSOR arm)

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

        + Biên dịch dịch lại cho lib mới RPI

        cd $HOME/Qt6Cross/qt6/pi-build
        cmake ../src/<thay thành tên lib của bạn VD : qtdeclarative-everywhere-src-6.5.1>/ -GNinja -DCMAKE_BUILD_TYPE=Release -DINPUT_opengl=es2 -DQT_BUILD_EXAMPLES=OFF -DQT_BUILD_TESTS=OFF -DQT_HOST_PATH=$HOME/Qt6Cross/qt6/host -DCMAKE_STAGING_PREFIX=$HOME/Qt6Cross/qt6/pi -DCMAKE_INSTALL_PREFIX=/usr/local/qt6 -DCMAKE_TOOLCHAIN_FILE=$HOME/Qt6Cross/qt6/pi-build/toolchain.cmake -DQT_QMAKE_TARGET_MKSPEC=devices/linux-rasp-pi4-aarch64 -DQT_FEATURE_xcb=ON -DFEATURE_xcb_xlib=ON -DQT_FEATURE_xlib=ON
        cmake --build . --parallel 8
        cmake --install .

        + Đồng bộ file bin đó sang cho raspberry pi 
            - lưu ý lỗi liên quan đến quyền thì sửa bỏ sudo 

            rsync -avz --rsync-path="sudo rsync" $HOME/Qt6Cross/qt6/pi/* <username>@<Địa chỉ raspbery pi của bạn>:/usr/local/qt6
        
IV. CÁC BƯỚC SET UP TRÊN IDE QT CREATE 

    - Lưu ý bạn cần phải tải qt phiên bản cũ về. 

    git clone git://code.qt.io/qt-creator/qt-creator.git
    git log --cherry-pick --pretty=oneline origin/v10.0.0..v10.0.1

    - Xem tiếp trong files word này 




        



    


