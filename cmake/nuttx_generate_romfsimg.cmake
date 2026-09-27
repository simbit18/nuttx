# ##############################################################################
# cmake/generate_romfsimg.cmake
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed to the Apache Software Foundation (ASF) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  The ASF licenses this
# file to you under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License.  You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.
#
# ##############################################################################

# ~~~
# Pure CMake replacement for:
#   sed -e "s/^unsigned char/const unsigned char aligned_data(4)/g" >> $@
#
# Invoked as:
#   cmake -DROMFS_SRC=<path> -DROMFS_SRC_TMP=<path> -P generate_romfsimg.cmake
# ~~~

if(NOT DEFINED ROMFS_SRC)
  message(FATAL_ERROR "ROMFS_SRC not set")
endif()

if(NOT DEFINED ROMFS_SRC_TMP)
  message(FATAL_ERROR "ROMFS_SRC_TMP not set")
endif()

file(READ "${ROMFS_SRC_TMP}" romfs_tmp_content)

# Equivalent of: sed -e "s/^unsigned char/const unsigned char aligned_data(4)/g"
string(REPLACE "unsigned char" "const unsigned char aligned_data(4)"
               XXD_OUTPUT_MODIFIED "${romfs_tmp_content}")

# Write the final source file: header first, then the modified xxd output
file(WRITE ${ROMFS_SRC} "#include <nuttx/compiler.h>\n")

file(APPEND ${ROMFS_SRC} "${XXD_OUTPUT_MODIFIED}")
