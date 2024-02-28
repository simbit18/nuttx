#!/usr/bin/env sh
############################################################################
# tools/ci/platforms/darwin.sh
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

# Darwin
# Prerequisites for macOS
#  - Xcode (cc, etc)
#  - homebrew
#  - autoconf
#  - wget

set -e
set -o xtrace

WD=$(cd "$(dirname "$0")" && pwd)
WORKSPACE=$(cd "${WD}"/../../../../ && pwd -P)
tools=${WORKSPACE}/tools
EXTRA_PATH=

add_path() {
  PATH=$1:${PATH}
  EXTRA_PATH=$1:${EXTRA_PATH}
}

arm_gcc_toolchain() {
  add_path "${tools}"/gcc-arm-none-eabi/bin

  if [ ! -f "${tools}/gcc-arm-none-eabi/bin/arm-none-eabi-gcc" ]; then
    local basefile
    basefile=arm-gnu-toolchain-13.2.rel1-darwin-x86_64-arm-none-eabi
    cd "${tools}"
    wget --quiet https://developer.arm.com/-/media/Files/downloads/gnu/13.2.rel1/binrel/${basefile}.tar.xz
    xz -d ${basefile}.tar.xz
    tar xf ${basefile}.tar
    mv ${basefile} gcc-arm-none-eabi
    rm ${basefile}.tar
  fi

  command arm-none-eabi-gcc --version
}

arm64_gcc_toolchain() {
  add_path "${tools}"/gcc-aarch64-none-elf/bin

  if [ ! -f "${tools}/gcc-aarch64-none-elf/bin/aarch64-none-elf-gcc" ]; then
    local basefile
    basefile=arm-gnu-toolchain-13.2.Rel1-darwin-x86_64-aarch64-none-elf
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

avr_gcc_toolchain() {
  if ! type avr-gcc > /dev/null 2>&1; then
    brew tap osx-cross/avr
    brew install avr-gcc
  fi

  command avr-gcc --version
}

binutils() {
  mkdir -p "${tools}"/bintools/bin
  add_path "${tools}"/bintools/bin

  if ! type objcopy > /dev/null 2>&1; then
    brew install binutils
    # It is possible we cached prebuilt but did brew install so recreate
    # symlink if it exists
    rm -f "${tools}"/bintools/bin/objcopy
    ln -s /usr/local/opt/binutils/bin/objcopy "${tools}"/bintools/bin/objcopy
  fi

  command objcopy --version
}

bloaty() {
  add_path "${tools}"/bloaty/bin

  if [ ! -f "${tools}/bloaty/bin/bloaty" ]; then
    git clone --branch main https://github.com/google/bloaty "${tools}"/bloaty-src
    cd "${tools}"/bloaty-src
    # Due to issues with latest MacOS versions use pinned commit.
    # https://github.com/google/bloaty/pull/326
    git checkout 52948c107c8f81045e7f9223ec02706b19cfa882
    mkdir -p "${tools}"/bloaty
    cmake -D BLOATY_PREFER_SYSTEM_CAPSTONE=NO -DCMAKE_INSTALL_PREFIX="${tools}"/bloaty
    cmake --build build
    cmake --build build --target install
    cd "${tools}"
    rm -rf bloaty-src
  fi

  command bloaty --version
}

c_cache() {
  add_path "${tools}"/ccache/bin

  if ! type ccache > /dev/null 2>&1; then
    brew install ccache
  fi
  setup_links
  command ccache --version
}

elf_toolchain() {
  if ! type x86_64-elf-gcc > /dev/null 2>&1; then
    brew install x86_64-elf-gcc
  fi

  command x86_64-elf-gcc --version
}

gen_romfs() {
  if ! type genromfs > /dev/null 2>&1; then
    brew tap PX4/px4
    brew install genromfs
  fi
}

gperf() {
  add_path "${tools}"/gperf/bin

  if [ ! -f "${tools}/gperf/bin/gperf" ]; then
    local basefile
    basefile=gperf-3.1

    cd "${tools}"
    wget --quiet http://ftp.gnu.org/pub/gnu/gperf/${basefile}.tar.gz
    tar zxf ${basefile}.tar.gz
    cd "${tools}"/${basefile}
    ./configure --prefix="${tools}"/gperf; make; make install
    cd "${tools}"
    rm -rf ${basefile}; rm ${basefile}.tar.gz
  fi

  command gperf --version
}

kconfig_frontends() {
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

mips_gcc_toolchain() {
  add_path "${tools}"/pinguino-compilers/macosx/p32/bin

  if [ ! -d "${tools}/pinguino-compilers" ]; then
    cd "${tools}"
    git clone https://github.com/PinguinoIDE/pinguino-compilers
  fi

  command mips-elf-gcc --version
}

python_tools() {
  # Python User Env
  export PIP_USER=yes
  export PYTHONUSERBASE=${tools}/pylocal
  echo "export PIP_USER=yes" >> "${tools}"/env.sh
  echo "export PYTHONUSERBASE=${tools}/pylocal" >> "${tools}"/env.sh
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

riscv_gcc_toolchain() {
  add_path "${tools}"/riscv-none-elf-gcc/bin

  if [ ! -f "${tools}/riscv-none-elf-gcc/bin/riscv-none-elf-gcc" ]; then
    local basefile
    basefile=xpack-riscv-none-elf-gcc-13.2.0-2-darwin-x64
    cd "${tools}"
    # Download the latest RISCV GCC toolchain prebuilt by xPack
    wget --quiet https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/${basefile}.tar.gz
    tar zxf ${basefile}.tar.gz
    mv xpack-riscv-none-elf-gcc-13.2.0-2 riscv-none-elf-gcc
    rm ${basefile}.tar.gz
  fi
  command riscv-none-elf-gcc --version
}

rust() {
  if ! type rustc > /dev/null 2>&1; then
    brew install rust
  fi

  command rustc --version
}

xtensa_esp32_gcc_toolchain() {
  add_path "${tools}"/xtensa-esp32-elf/bin

  if [ ! -f "${tools}/xtensa-esp32-elf/bin/xtensa-esp32-elf-gcc" ]; then
    local basefile
    basefile=xtensa-esp32-elf-12.2.0_20230208-x86_64-apple-darwin
    cd "${tools}"
    wget --quiet https://github.com/espressif/crosstool-NG/releases/download/esp-12.2.0_20230208/${basefile}.tar.xz
    xz -d ${basefile}.tar.xz
    tar xf ${basefile}.tar
    rm ${basefile}.tar
  fi

  command xtensa-esp32-elf-gcc --version
}

u_boot_tools() {
  if ! type mkimage > /dev/null 2>&1; then
    brew install u-boot-tools
  fi
}

util_linux() {
  if ! type flock > /dev/null 2>&1; then
    brew tap discoteq/discoteq
    brew install flock
  fi

  command flock --version
}

wasi_sdk() {
  add_path "${tools}"/wamrc

  if [ ! -f "${tools}/wamrc/wasi-sdk/bin/clang" ]; then
    local wasibasefile
    local wasmbasefile
    wasibasefile=wasi-sdk-19.0-macos
    wasmbasefile=wamrc-1.1.2-x86_64-macos-latest
    cd "${tools}"
    mkdir wamrc
    wget --quiet https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-19/${wasibasefile}.tar.gz
    tar xzf ${wasibasefile}.tar.gz
    mv wasi-sdk-19.0 wasi-sdk
    rm ${wasibasefile}.tar.gz
    cd wamrc
    wget --quiet https://github.com/bytecodealliance/wasm-micro-runtime/releases/download/WAMR-1.1.2/${wasmbasefile}.tar.gz
    tar xzf ${wasmbasefile}.tar.gz
    rm ${wasmbasefile}.tar.gz
  fi

  export WASI_SDK_PATH="${tools}/wasi-sdk"
  echo "export WASI_SDK_PATH=${tools}/wasi-sdk" >> "${tools}"/env.sh

  command "${WASI_SDK_PATH}"/bin/clang --version
  command wamrc --version
}

setup_links() {
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

install_build_tools() {
  mkdir -p "${tools}"
  echo "#!/usr/bin/env sh" > "${tools}"/env.sh
  # install="arm_gcc_toolchain arm64_gcc_toolchain avr_gcc_toolchain binutils bloaty elf_toolchain gen_romfs gperf kconfig_frontends mips_gcc_toolchain python_tools riscv_gcc_toolchain rust xtensa_esp32_gcc_toolchain u_boot_tools util_linux wasi_sdk c_cache"
  install="arm_gcc_toolchain binutils elf_toolchain gen_romfs gperf kconfig_frontends python_tools u_boot_tools util_linux c_cache"
  mkdir -p "${tools}"/homebrew
  export HOMEBREW_CACHE=${tools}/homebrew
  echo "export HOMEBREW_CACHE=${tools}/homebrew" >> "${tools}"/env.sh
  # https://github.com/apache/arrow/issues/15025
  rm -f /usr/local/bin/2to3* || :
  rm -f /usr/local/bin/idle3* || :
  rm -f /usr/local/bin/pydoc3* || :
  rm -f /usr/local/bin/python3* || :
  rm -f /usr/local/bin/python3-config || :
  # same for openssl
  rm -f /usr/local/bin/openssl || :

  oldpath=$(cd . && pwd -P)
  for func in ${install}; do
    ${func}
  done
  cd "${oldpath}"

  echo "PATH=${PATH}" >> "${tools}"/env.sh
  echo "export PATH" >> "${tools}"/env.sh
}

install_build_tools
