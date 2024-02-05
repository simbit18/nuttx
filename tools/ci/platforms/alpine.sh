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
  if ! type clang &> /dev/null; then
    apk --no-cache --update add clang
  fi
  
  which clang
  clang --version
}

function arm-gcc-toolchain {
  if ! type arm-none-eabi-gcc &> /dev/null; then
    apk --no-cache --update add clang \
          gcc-arm-none-eabi \
          newlib-arm-none-eabi \
          g++-arm-none-eabi
  fi

  which arm-none-eabi-gcc
  arm-none-eabi-gcc --version
}

function arm64-gcc-toolchain {
  if ! type aarch64-none-elf-gcc &> /dev/null; then
    apk --no-cache --update add gcc-aarch64-none-elf
  fi
  
  aarch64-none-elf-gcc --version
}

function avr-gcc-toolchain {
  if ! type avr-gcc &> /dev/null; then
    apk --no-cache --update add gcc-avr
  fi

  avr-gcc --version
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

function riscv-gcc-toolchain {
  if ! type riscv-none-elf-gcc &> /dev/null; then
    apk --no-cache --update add gcc-riscv-none-elf
  fi
  
  riscv-none-elf-gcc --version
  
}

function rust {
  if ! type rustc &> /dev/null; then
    apk --no-cache --update add rust cargo
  fi

  rustc --version
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
