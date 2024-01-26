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

set -e
set -o xtrace


CID=$(cd "$(dirname "$0")" && pwd)
CIWORKSPACE=$(cd "${CID}"/../../../ && pwd -P)
CIPLAT=${CIWORKSPACE}/nuttx/tools/ci/platform

os=$(uname -s)
# osname=$(grep '^NAME=' /etc/os-release)
if [ "X$os" == "XDarwin" ]; then
  osname="Darwin"
else
  osname=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
fi

EXTRA_PATH=

function to_do {
  echo ""
  echo "NuttX TODO: $1"
  echo "The $1 platform does not appear to have been added to this project."
  echo ""
  exit 1
}

function find_platform {

  case ${osname} in
    alpine)
      to_do "alpine"
      ;;
    arch)
      to_do "arch"
      ;;
    debian)
      to_do "debian"
      ;;
    fedora)
      to_do "fedora"
      ;;
    freebsd)
      to_do "freebsd"
      ;;
    Darwin)
      "${CIPLAT}"/darwin.sh ${ciarg}
      ;;
    Linux)
      "${CIPLAT}"/linux.sh ${ciarg}
      ;;
    manjaro)
      to_do "manjaro"
      ;;
    msys2)
      "${CIPLAT}"/msys2.sh ${ciarg}
      ;;
    rocky)
      to_do "rocky"
      ;;
    ubuntu)
      "${CIPLAT}"/linux.sh ${ciarg}
      ;;
    *)
       to_do "unknown"
      ;;
  esac

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

if [ -z "$1" ]; then
  usage
else
  ciarg="$@"
fi

find_platform
