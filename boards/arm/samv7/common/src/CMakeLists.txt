# ##############################################################################
# boards/arm/samv7/common/src/CMakeLists.txt
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

if(CONFIG_ARCH_BOARD_COMMON)

  list(APPEND SRCS sam_reset.c)

  if(CONFIG_BOARDCTL_BOOT_IMAGE)
    list(APPEND SRCS sam_boot_image.c)
  endif()

  if(CONFIG_SAMV7_PROGMEM)
    if(CONFIG_MTD_PROGMEM)
      list(APPEND SRCS sam_progmem.c)
    endif()
  endif()

  if(CONFIG_SAMV7_HSMCI0)
    list(APPEND SRCS sam_hsmci.c)
  endif()

  if(CONFIG_FS_AUTOMOUNTER)
    list(APPEND SRCS sam_automount.c)
  endif()

  if(CONFIG_SAMV7_GPIO_ENC)
    list(APPEND SRCS sam_gpio_enc.c)
  endif()

  if(CONFIG_SAMV7_UART_RXDMA_POLL)
    list(APPEND SRCS sam_uart_rxdma_poll.c)
  endif()

endif()

target_sources(board PRIVATE ${SRCS})
