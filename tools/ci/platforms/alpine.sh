#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# LINUX

set -e
set -o xtrace

WD=$(cd "$(dirname "$0")" && pwd)
WORKSPACE=$(cd "${WD}"/../../../../ && pwd -P)
nuttx=${WORKSPACE}/nuttx
apps=${WORKSPACE}/apps
tools=${WORKSPACE}/tools
# os=$(uname -s)
# osname=$(grep '^NAME=' /etc/os-release)
# osname=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
EXTRA_PATH=

function add_path {
  PATH=$1:${PATH}
  EXTRA_PATH=$1:${EXTRA_PATH}
echo ${PATH}
}

function arm-clang-toolchain {
  add_path "${tools}"/clang-arm-none-eabi/bin

  if [ ! -f "${tools}/clang-arm-none-eabi/bin/clang" ]; then
    local basefile
    basefile=LLVMEmbeddedToolchainForArm-17.0.1-Linux-x86_64

    cd "${tools}"
    # Download the latest ARM clang toolchain prebuilt by ARM
    curl -O -L -s https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-17.0.1/${basefile}.tar.xz
    xz -d ${basefile}.tar.xz
    tar xf ${basefile}.tar
    mv ${basefile} clang-arm-none-eabi
    # cp /usr/bin/clang-extdef-mapping-10 clang-arm-none-eabi/bin/clang-extdef-mapping
    rm ${basefile}.tar
  fi
  which clang
  # clang --version
}

function arm-gcc-toolchain {
  add_path "${tools}"/gcc-arm-none-eabi/bin

  if [ ! -f "${tools}/gcc-arm-none-eabi/bin/arm-none-eabi-gcc" ]; then
    local basefile
    basefile=arm-gnu-toolchain-13.2.Rel1-x86_64-arm-none-eabi

    cd "${tools}"
    # Download the latest ARM GCC toolchain prebuilt by ARM
    wget --quiet https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/${basefile}.tar.xz
    xz -d ${basefile}.tar.xz
    tar xf ${basefile}.tar
    mv ${basefile} gcc-arm-none-eabi
    rm ${basefile}.tar
  fi
  which arm-none-eabi-gcc
  # arm-none-eabi-gcc --version
}

function arm64-gcc-toolchain {
  add_path "${tools}"/gcc-aarch64-none-elf/bin

  if [ ! -f "${tools}/gcc-aarch64-none-elf/bin/aarch64-none-elf-gcc" ]; then
    local basefile
    basefile=arm-gnu-toolchain-13.2.Rel1-x86_64-aarch64-none-elf

    cd "${tools}"
    # Download the latest ARM64 GCC toolchain prebuilt by ARM
    wget --quiet https://developer.arm.com/-/media/Files/downloads/gnu/13.2.Rel1/binrel/${basefile}.tar.xz
    xz -d ${basefile}.tar.xz
    tar xf ${basefile}.tar
    mv ${basefile} gcc-aarch64-none-elf
    rm ${basefile}.tar
  fi

  command aarch64-none-elf-gcc --version
}

function avr-gcc-toolchain {
  if ! type avr-gcc &> /dev/null; then
    apt-get install -y avr-libc gcc-avr
  fi

  command avr-gcc --version
}

function binutils {
  if ! type objcopy &> /dev/null; then
    apt-get install -y binutils-dev
  fi

  command objcopy --version
}

function bloaty {
  add_path "${tools}"/bloaty/bin

  if [ ! -f "${tools}/bloaty/bin/bloaty" ]; then
    git clone --branch main https://github.com/google/bloaty "${tools}"/bloaty-src
    cd "${tools}"/bloaty-src
    # Due to issues with latest MacOS versions use pinned commit.
    # https://github.com/google/bloaty/pull/326
    git checkout 52948c107c8f81045e7f9223ec02706b19cfa882
    mkdir -p "${tools}"/bloaty
    cmake -D BLOATY_PREFER_SYSTEM_CAPSTONE=NO -DCMAKE_SYSTEM_PREFIX_PATH="${tools}"/bloaty
    make install
    cd "${tools}"
    rm -rf bloaty-src
  fi

  command bloaty --version
}

function c-cache {
  add_path "${tools}"/ccache/bin

  if ! type ccache &> /dev/null; then
    local basefile
    basefile=ccache-3.7.7
    cd "${tools}";
    wget https://github.com/ccache/ccache/releases/download/v3.7.7/${basefile}.tar.gz
    tar zxf ${basefile}.tar.gz
    cd ${basefile}; ./configure --prefix="${tools}"/ccache; make; make install
    cd "${tools}"; rm -rf ${basefile}; rm ${basefile}.tar.gz
  fi

  command ccache --version
}

function clang-tidy {
  if ! type clang-tidy &> /dev/null; then
    apt-get install -y clang clang-tidy
  fi

  command clang-tidy --version
}

function util-linux {
  if ! type flock &> /dev/null; then
    apt-get install -y util-linux
  fi

  command flock --version
}

function gen-romfs {
  add_path "${tools}"/genromfs/usr/bin

  if ! type genromfs &> /dev/null; then
    git clone https://bitbucket.org/nuttx/tools.git "${tools}"/nuttx-tools
    cd "${tools}"/nuttx-tools
    tar zxf genromfs-0.5.2.tar.gz
    cd genromfs-0.5.2
    make install PREFIX="${tools}"/genromfs
    cd "${tools}"
    rm -rf nuttx-tools
  fi
}

function kconfig-frontends {
  add_path "${tools}"/kconfig-frontends/bin

  if [ ! -f "${tools}/kconfig-frontends/bin/kconfig-conf" ]; then
    git clone https://bitbucket.org/nuttx/tools.git "${tools}"/nuttx-tools
    cd "${tools}"/nuttx-tools/kconfig-frontends
    ./configure --prefix="${tools}"/kconfig-frontends \
      --enable-mconf --disable-nconf --disable-gconf --disable-qconf
    ln -s /usr/bin/aclocal /usr/local/bin/aclocal-1.15
    ln -s /usr/bin/automake /usr/local/bin/automake-1.15
    make install
    cd "${tools}"
    rm -rf nuttx-tools
  fi
}

function mips-gcc-toolchain {
  add_path "${tools}"/pinguino-compilers/linux64/p32/bin

  if [ ! -d "${tools}/pinguino-compilers" ]; then
    cd "${tools}"
    git clone https://github.com/PinguinoIDE/pinguino-compilers
  fi

  command p32-gcc --version
}

function python-tools {
  # Python User Env
  export PIP_USER=yes
  export PYTHONUSERBASE=${tools}/pylocal
  add_path "${PYTHONUSERBASE}"/bin

  # workaround for Cython issue
  # https://github.com/yaml/pyyaml/pull/702#issuecomment-1638930830
  pip3 install "Cython<3.0"
  git clone https://github.com/yaml/pyyaml.git && \
  cd pyyaml && \
  git checkout release/5.4.1 && \
  sed -i.bak 's/Cython/Cython<3.0/g' pyproject.toml && \
  python setup.py sdist && \
  pip3 install --pre dist/PyYAML-5.4.1.tar.gz
  cd ..

  pip3 install \
    cmake-format \
    CodeChecker \
    cvt2utf \
    cxxfilt \
    esptool==4.5.1 \
    imgtool==1.9.0 \
    kconfiglib \
    pexpect==4.8.0 \
    pyelftools \
    pyserial==3.5 \
    pytest==6.2.5 \
    pytest-json==0.4.0 \
    pytest-ordering==0.6 \
    pytest-repeat==0.9.1
}

function riscv-gcc-toolchain {
  add_path "${tools}"/riscv-none-elf-gcc/bin

  if [ ! -f "${tools}/riscv-none-elf-gcc/bin/riscv-none-elf-gcc" ]; then
    local basefile
    basefile=xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64

    cd "${tools}"
    # Download the latest RISCV GCC toolchain prebuilt by xPack
    wget --quiet https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/${basefile}.tar.gz
    tar zxf ${basefile}.tar.gz
    mv xpack-riscv-none-elf-gcc-13.2.0-2 riscv-none-elf-gcc
    rm ${basefile}.tar.gz
  fi
  command riscv-none-elf-gcc --version
}

function rust {
  add_path "${tools}"/rust/bin

  if ! type rustc &> /dev/null; then
    mkdir -p "${tools}"/rust/bin
    # Currently Debian installed rustc doesn't support 2021 edition.
    export CARGO_HOME=${tools}/rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  fi

  command rustc --version
}

function rx-gcc-toolchain {
  add_path "${tools}"/renesas-toolchain/rx-elf-gcc/bin

  if [ ! -f "${tools}/renesas-toolchain/rx-elf-gcc/bin/rx-elf-gcc" ]; then
        # Download toolchain source code
        # RX toolchain is built from source code. Once prebuilt RX toolchain is made available, the below code snippet can be removed.
        mkdir -p "${tools}"/renesas-tools/rx/source; cd "${tools}"/renesas-tools/rx/source
        wget --quiet https://gcc-renesas.com/downloads/d.php?f=rx/binutils/4.8.4.201803-gnurx/rx_binutils2.24_2018Q3.tar.gz \
          -O rx_binutils2.24_2018Q3.tar.gz
        tar zxf rx_binutils2.24_2018Q3.tar.gz
        wget --quiet https://gcc-renesas.com/downloads/d.php?f=rx/gcc/4.8.4.201803-gnurx/rx_gcc_4.8.4_2018Q3.tar.gz \
          -O rx_gcc_4.8.4_2018Q3.tar.gz
        tar zxf rx_gcc_4.8.4_2018Q3.tar.gz
        wget --quiet https://gcc-renesas.com/downloads/d.php?f=rx/newlib/4.8.4.201803-gnurx/rx_newlib2.2.0_2018Q3.tar.gz \
          -O rx_newlib2.2.0_2018Q3.tar.gz
        tar zxf rx_newlib2.2.0_2018Q3.tar.gz

        # Install binutils
        cd "${tools}"/renesas-tools/rx/source/binutils; chmod +x ./configure ./mkinstalldirs
        mkdir -p "${tools}"/renesas-tools/rx/build/binutils; cd "${tools}"/renesas-tools/rx/build/binutils
        "${tools}"/renesas-tools/rx/source/binutils/configure --target=rx-elf --prefix="${tools}"/renesas-toolchain/rx-elf-gcc \
          --disable-werror
        make; make install

        # Install gcc
        cd "${tools}"/renesas-tools/rx/source/gcc
        chmod +x ./contrib/download_prerequisites ./configure ./move-if-change ./libgcc/mkheader.sh
        ./contrib/download_prerequisites
        sed -i '1s/^/@documentencoding ISO-8859-1\n/' ./gcc/doc/gcc.texi
        sed -i 's/@tex/\n&/g' ./gcc/doc/gcc.texi && sed -i 's/@end tex/\n&/g' ./gcc/doc/gcc.texi
        mkdir -p "${tools}"/renesas-tools/rx/build/gcc; cd "${tools}"/renesas-tools/rx/build/gcc
        "${tools}"/renesas-tools/rx/source/gcc/configure --target=rx-elf --prefix="${tools}"/renesas-toolchain/rx-elf-gcc \
        --disable-shared --disable-multilib --disable-libssp --disable-libstdcxx-pch --disable-werror --enable-lto \
        --enable-gold --with-pkgversion=GCC_Build_1.02 --with-newlib --enable-languages=c
        make; make install

        # Install newlib
        cd "${tools}"/renesas-tools/rx/source/newlib; chmod +x ./configure
        mkdir -p "${tools}"/renesas-tools/rx/build/newlib; cd "${tools}"/renesas-tools/rx/build/newlib
        "${tools}"/renesas-tools/rx/source/newlib/configure --target=rx-elf --prefix="${tools}"/renesas-toolchain/rx-elf-gcc
        make; make install
        rm -rf "${tools}"/renesas-tools/
  fi

  command rx-elf-gcc --version
}

function sparc-gcc-toolchain {
  add_path "${tools}"/sparc-gaisler-elf-gcc/bin

  if [ ! -f "${tools}/sparc-gaisler-elf-gcc/bin/sparc-gaisler-elf-gcc" ]; then
    local basefile
    basefile=bcc-2.1.0-gcc-linux64
    cd "${tools}"

    # Download the SPARC GCC toolchain prebuilt by Gaisler
    wget --quiet https://www.gaisler.com/anonftp/bcc2/bin/${basefile}.tar.xz
    xz -d ${basefile}.tar.xz
    tar xf ${basefile}.tar
    mv bcc-2.1.0-gcc sparc-gaisler-elf-gcc
    rm ${basefile}.tar
  fi

  command sparc-gaisler-elf-gcc --version
}

function xtensa-esp32-gcc-toolchain {
  add_path "${tools}"/xtensa-esp32-elf/bin

  if [ ! -f "${tools}/xtensa-esp32-elf/bin/xtensa-esp32-elf-gcc" ]; then
    local basefile
    basefile=xtensa-esp32-elf-12.2.0_20230208-x86_64-linux-gnu
    cd "${tools}"

    # Download the latest ESP32 GCC toolchain prebuilt by Espressif
    wget --quiet https://github.com/espressif/crosstool-NG/releases/download/esp-12.2.0_20230208/${basefile}.tar.xz
    xz -d ${basefile}.tar.xz
    tar xf ${basefile}.tar
    rm ${basefile}.tar
  fi

  command xtensa-esp32-elf-gcc --version
}

function xtensa-esp32s2-gcc-toolchain {
  add_path "${tools}"/xtensa-esp32s2-elf/bin

  if [ ! -f "${tools}/xtensa-esp32s2-elf/bin/xtensa-esp32s2-elf-gcc" ]; then
    local basefile
    basefile=xtensa-esp32s2-elf-12.2.0_20230208-x86_64-linux-gnu
    cd "${tools}"

    # Download the latest ESP32 S2 GCC toolchain prebuilt by Espressif
    wget --quiet https://github.com/espressif/crosstool-NG/releases/download/esp-12.2.0_20230208/${basefile}.tar.xz
    xz -d ${basefile}.tar.xz
    tar xf ${basefile}.tar
    rm ${basefile}.tar
  fi

  command xtensa-esp32s2-elf-gcc --version
}

function xtensa-esp32s3-gcc-toolchain {
  add_path "${tools}"/xtensa-esp32s3-elf/bin

  if [ ! -f "${tools}/xtensa-esp32s3-elf/bin/xtensa-esp32s3-elf-gcc" ]; then
    local basefile
    basefile=xtensa-esp32s3-elf-12.2.0_20230208-x86_64-linux-gnu
    cd "${tools}"

    # Download the latest ESP32 S3 GCC toolchain prebuilt by Espressif
    wget --quiet https://github.com/espressif/crosstool-NG/releases/download/esp-12.2.0_20230208/${basefile}.tar.xz
    xz -d ${basefile}.tar.xz
    tar xf ${basefile}.tar
    rm ${basefile}.tar
  fi

  command xtensa-esp32s3-elf-gcc --version
}

function u-boot-tools {
  if ! type mkimage &> /dev/null; then
    apt-get install -y u-boot-tools
  fi
}

function wasi-sdk {
  add_path "${tools}"/wamrc

  if [ ! -f "${tools}/wasi-sdk/bin/clang" ]; then
    local wasibasefile
    local wasmbasefile
    wasibasefile=wasi-sdk-19.0-linux
    wasmbasefile=wamrc-1.1.2-x86_64-ubuntu-20.04
    cd "${tools}"
    mkdir wamrc

    # Download the latest WASI-enabled WebAssembly C/C++ toolchain prebuilt by WASM
    wget --quiet https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-19/${wasibasefile}.tar.gz
    tar xzf ${wasibasefile}.tar.gz
    mv wasi-sdk-19.0 wasi-sdk
    rm ${wasibasefile}.tar
    cd wamrc
    # Download the latest "wamrc" AOT compiler prebuilt by WAMR
    wget --quiet https://github.com/bytecodealliance/wasm-micro-runtime/releases/download/WAMR-1.1.2/${wasmbasefile}.tar.gz
    tar xzf ${wasmbasefile}.tar.gz
    rm ${wasmbasefile}.tar

  fi

  export WASI_SDK_PATH="${tools}/wasi-sdk"

  command ${WASI_SDK_PATH}/bin/clang --version
  command wamrc --version
}

function usage {
  echo ""
  echo "USAGE: $0 [-i] [-s] [-c] [-*] <testlist>"
  echo "       $0 -h"
  echo ""
  echo "Where:"
  echo "  -i install tools"
  echo "  -s setup repos"
  echo "  -c enable ccache"
  echo "  -* support all options in testbuild.sh"
  echo "  -h will show this help test and terminate"
  echo "  <testlist> select testlist file"
  echo ""
  exit 1
}

function enable_ccache {
  export CCACHE_DIR="${tools}"/ccache
}

function setup_links {
  # Configure ccache
  mkdir -p "${tools}"/ccache/bin/
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/aarch64-none-elf-gcc
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/aarch64-none-elf-g++
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/arm-none-eabi-gcc
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/arm-none-eabi-g++
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/avr-gcc
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/avr-g++
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/cc
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/c++
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/clang
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/clang++
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/gcc
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/g++
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/p32-gcc
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/riscv64-unknown-elf-gcc
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/riscv64-unknown-elf-g++
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/sparc-gaisler-elf-gcc
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/sparc-gaisler-elf-g++
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/x86_64-elf-gcc
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/x86_64-elf-g++
  ln -sf "$(which ccache)" "${tools}"/ccache/bin/xtensa-esp32-elf-gcc
}

function setup_repos {
  pushd .
  if [ -d "${nuttx}" ]; then
    cd "${nuttx}"; git pull
  else
    git clone https://github.com/apache/nuttx.git "${nuttx}"
    cd "${nuttx}"
  fi
  git log -1

  if [ -d "${apps}" ]; then
    cd "${apps}"; git pull
  else
    git clone https://github.com/apache/nuttx-apps.git "${apps}"
    cd "${apps}"
  fi
  git log -1
  popd
}

function install_tools {
  mkdir -p "${tools}"

    install="arm-clang-toolchain arm-gcc-toolchain gen-romfs kconfig-frontends"

  pushd .
  for func in ${install}; do
    ${func}
  done
  popd

  if [ -d "${CCACHE_DIR}" ]; then
    setup_links
  fi
  echo PATH="${EXTRA_PATH}"/"${PATH}" > "${tools}"/env.sh
}

function run_builds {
  local ncpus
  ncpus=$(grep -c ^processor /proc/cpuinfo)

  options+="-j ${ncpus}"

  for build in "${builds[@]}"; do
    "${nuttx}"/tools/testbuild.sh ${options} -e "-Wno-cpp -Werror" "${build}"
  done

  if [ -d "${CCACHE_DIR}" ]; then
    # Print a summary of configuration and statistics counters
    ccache -s
  fi
}

if [ -z "$1" ]; then
   usage
fi

while [ -n "$1" ]; do
  case "$1" in
  -h )
    usage
    ;;
  -i )
    install_tools
    ;;
  -c )
    enable_ccache
    ;;
  -s )
    setup_repos
    ;;
  -* )
    options+="$1 "
    ;;
  * )
    builds=( "$@" )
    break
    ;;
  esac
  shift
done

run_builds
