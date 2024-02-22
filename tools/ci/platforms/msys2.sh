#!/usr/bin/env bash
############################################################################
# tools/ci/platforms/msys2.sh
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.  The
# ASF licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#
############################################################################

# MSYS2

set -e
set -o xtrace

WD=$(cd "$(dirname "$0")" && pwd)
WORKSPACE=$(cd "${WD}"/../../../../ && pwd -P)
tools=${WORKSPACE}/tools
EXTRA_PATH=

function add_path {
  PATH=$1:${PATH}
  EXTRA_PATH=$1:${EXTRA_PATH}
}

function arm-clang-toolchain {
  add_path "${tools}"/clang-arm-none-eabi/bin

  if [ ! -f "${tools}/clang-arm-none-eabi/bin/clang" ]; then
    local basefile
    basefile=LLVMEmbeddedToolchainForArm-17.0.1-Windows-x86_64
    cd "${tools}"
    # Download the latest ARM clang toolchain prebuilt by ARM
    curl -O -L -s https://github.com/ARM-software/LLVM-embedded-toolchain-for-Arm/releases/download/release-17.0.1/${basefile}.zip
    unzip -qo ${basefile}.zip
    mv ${basefile} clang-arm-none-eabi
    rm ${basefile}.zip
  fi

  command clang --version
}

function arm-gcc-toolchain {
  add_path "${tools}"/gcc-arm-none-eabi/bin

  if [ ! -f "${tools}/gcc-arm-none-eabi/bin/arm-none-eabi-gcc" ]; then
    local basefile
    basefile=arm-gnu-toolchain-13.2.Rel1-mingw-w64-i686-arm-none-eabi
    cd "${tools}"
    wget --quiet https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/${basefile}.zip
    unzip -qo ${basefile}.zip
    mv ${basefile} gcc-arm-none-eabi
    rm ${basefile}.zip
  fi

  command arm-none-eabi-gcc --version
}

function arm64-gcc-toolchain {
  add_path "${tools}"/gcc-aarch64-none-elf/bin

  if [ ! -f "${tools}/gcc-aarch64-none-elf/bin/aarch64-none-elf-gcc" ]; then
    local basefile
    basefile=arm-gnu-toolchain-13.2.rel1-mingw-w64-i686-aarch64-none-elf
    cd "${tools}"
    # Download the latest ARM64 GCC toolchain prebuilt by ARM
    wget --quiet https://developer.arm.com/-/media/Files/downloads/gnu/13.2.Rel1/binrel/${basefile}.zip
    unzip -qo ${basefile}.zip
    mv ${basefile} gcc-aarch64-none-elf
    rm ${basefile}.zip
  fi

  command aarch64-none-elf-gcc --version
}

function c-cache {
  add_path "${tools}"/ccache/bin

  if ! type ccache &> /dev/null; then
    pacman -S --noconfirm --needed ccache
    pacman -Q
  fi
  setup_links
  command ccache --version
}

function esp-tool {
  add_path "${tools}"/esp-tool

  if ! type esptool &> /dev/null; then
    local basefile
    basefile=esptool-v4.7.0-win64
    cd "${tools}"
    curl -O -L -s https://github.com/espressif/esptool/releases/download/v4.7.0/${basefile}.zip
    unzip -qo ${basefile}.zip
    mv esptool-win64 esp-tool
    rm ${basefile}.zip
  fi
  command esptool version
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
      --disable-kconfig --disable-nconf --disable-qconf \
      --disable-gconf --disable-mconf --disable-static \
      --disable-shared --disable-L10n
    # Avoid "aclocal/automake missing" errors
    touch aclocal.m4 Makefile.in
    make install
    cd "${tools}"
    rm -rf nuttx-tools
  fi
}

function riscv-gcc-toolchain {
  add_path "${tools}"/riscv-none-elf-gcc/bin

  if [ ! -f "${tools}/riscv-none-elf-gcc/bin/riscv-none-elf-gcc" ]; then
    local basefile
    basefile=xpack-riscv-none-elf-gcc-13.2.0-2-win32-x64
    cd "${tools}"
    # Download the latest RISCV GCC toolchain prebuilt by xPack
    wget --quiet https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/${basefile}.zip
    unzip -qo ${basefile}.zip
    mv xpack-riscv-none-elf-gcc-13.2.0-2 riscv-none-elf-gcc
    rm ${basefile}.zip
  fi
  command riscv-none-elf-gcc --version
}

function rust {
  add_path "${tools}"/rust/cargo/bin
  # Configuring the PATH environment variable
  export CARGO_HOME=${tools}/rust/cargo
  export RUSTUP_HOME=${tools}/rust/rustup
  if ! type rustc &> /dev/null; then
    local basefile
    basefile=x86_64-pc-windows-gnu
    mkdir -p "${tools}"/rust
    cd "${tools}"
    # Download tool rustup-init.exe
    curl -O -L -s https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-gnu/rustup-init.exe
    # Install Rust target x86_64-pc-windows-gnu
    ./rustup-init.exe -y --default-host ${basefile} --no-modify-path
    # Install targets supported from NuttX
    $CARGO_HOME/bin/rustup target add thumbv6m-none-eabi
    $CARGO_HOME/bin/rustup target add thumbv7m-none-eabi
    rm rustup-init.exe
  fi
  command rustc --version
}

function sparc-gcc-toolchain {
  add_path "${tools}"/sparc-gaisler-elf-gcc/bin

  if [ ! -f "${tools}/sparc-gaisler-elf-gcc/bin/sparc-gaisler-elf-gcc" ]; then
    local basefile
    basefile=bcc-2.1.0-gcc-mingw64
    cd "${tools}"
    # Download the SPARC GCC toolchain prebuilt by Gaisler
    wget --quiet https://www.gaisler.com/anonftp/bcc2/bin/${basefile}.zip
    unzip -qo ${basefile}.zip
    mv bcc-2.1.0-gcc sparc-gaisler-elf-gcc
    rm ${basefile}.zip
  fi

  command sparc-gaisler-elf-gcc --version
}

function xtensa-esp32-gcc-toolchain {
  add_path "${tools}"/xtensa-esp32-elf/bin

  if [ ! -f "${tools}/xtensa-esp32-elf/bin/xtensa-esp32-elf-gcc" ]; then
    local basefile
    basefile=xtensa-esp32-elf-12.2.0_20230208-x86_64-w64-mingw32
    cd "${tools}"
    # Download the latest ESP32 GCC toolchain prebuilt by Espressif
    wget --quiet https://github.com/espressif/crosstool-NG/releases/download/esp-12.2.0_20230208/${basefile}.zip
    unzip -qo ${basefile}.zip
    rm ${basefile}.zip
  fi

  command xtensa-esp32-elf-gcc --version
}

function xtensa-esp32s2-gcc-toolchain {
  add_path "${tools}"/xtensa-esp32s2-elf/bin

  if [ ! -f "${tools}/xtensa-esp32s2-elf/bin/xtensa-esp32s2-elf-gcc" ]; then
    local basefile
    basefile=xtensa-esp32s2-elf-12.2.0_20230208-x86_64-w64-mingw32
    cd "${tools}"
    # Download the latest ESP32 S2 GCC toolchain prebuilt by Espressif
    wget --quiet https://github.com/espressif/crosstool-NG/releases/download/esp-12.2.0_20230208/${basefile}.zip
    unzip -qo ${basefile}.zip
    rm ${basefile}.zip
  fi

  command xtensa-esp32s2-elf-gcc --version
}

function xtensa-esp32s3-gcc-toolchain {
  add_path "${tools}"/xtensa-esp32s3-elf/bin

  if [ ! -f "${tools}/xtensa-esp32s3-elf/bin/xtensa-esp32s3-elf-gcc" ]; then
    local basefile
    basefile=xtensa-esp32s3-elf-12.2.0_20230208-x86_64-w64-mingw32
    cd "${tools}"
    # Download the latest ESP32 S3 GCC toolchain prebuilt by Espressif
    wget --quiet https://github.com/espressif/crosstool-NG/releases/download/esp-12.2.0_20230208/${basefile}.zip
    unzip -qo ${basefile}.zip
    rm ${basefile}.zip
  fi

  command xtensa-esp32s3-elf-gcc --version
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

function install_build_tools {
  mkdir -p "${tools}"

  install="arm-clang-toolchain arm-gcc-toolchain arm64-gcc-toolchain kconfig-frontends riscv-gcc-toolchain rust"

  pushd .
  for func in ${install}; do
    ${func}
  done
  popd

  echo "#!/usr/bin/env bash" > "${tools}"/env.sh
  echo "PATH=${PATH}" >> "${tools}"/env.sh
  echo "export PATH" >> "${tools}"/env.sh
  source "${tools}"/env.sh
}

install_build_tools
