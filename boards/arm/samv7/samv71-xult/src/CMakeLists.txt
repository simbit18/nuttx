# ##############################################################################
# boards/arm/samv7/samv71-xult/src/CMakeLists.txt
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

set(SRCS sam_boot.c)

if(CONFIG_SAMV7_SDRAMC)
  list(APPEND SRCS sam_sdram.c)
endif()

if(CONFIG_BOARDCTL)
  list(APPEND SRCS sam_appinit.c sam_bringup.c)
elseif(CONFIG_BOARD_LATE_INITIALIZE)
  list(APPEND SRCS sam_bringup.c)
endif()

if(CONFIG_ARCH_LEDS)
  list(APPEND SRCS sam_autoleds.c)
else()
  list(APPEND SRCS sam_userleds.c)
endif()

if(CONFIG_ARCH_BUTTONS)
  list(APPEND SRCS sam_buttons.c)
endif()

if(CONFIG_SAMV7_EMAC)
  list(APPEND SRCS sam_ethernet.c)
endif()

if(CONFIG_SAMV7_USBDEVHS)
  list(APPEND SRCS sam_usbdev.c)
endif()

if(CONFIG_SAMV7_SPI)
  list(APPEND SRCS sam_spi.c)
endif()

if(CONFIG_USBMSC)
  list(APPEND SRCS sam_usbmsc.c)
endif()

if(CONFIG_USBDEV_COMPOSITE)
  list(APPEND SRCS sam_composite.c)
endif()

if(CONFIG_SAMV7_MCAN)
  list(APPEND SRCS sam_mcan.c)
endif()

if(CONFIG_AUDIO_WM8904)
  if(CONFIG_SAMV7_TWIHS0)
    if(CONFIG_SAMV7_SSC0)
      list(APPEND SRCS sam_wm8904.c)
    endif()
  endif()
endif()

if(CONFIG_AUDIO_NULL)
  list(APPEND SRCS sam_audio_null.c)
endif()

if(NOT CONFIG_MTD_CONFIG_NONE)
  if(CONFIG_SAMV7_TWIHS0)
    if(CONFIG_MTD_AT24XX)
      list(APPEND SRCS sam_at24config.c)
    endif()
  endif()
endif()

if(CONFIG_SAMV71XULT_MXTXPLND)
  if(CONFIG_LCD)
    list(APPEND SRCS sam_ili9488.c)
  endif()
  if(CONFIG_INPUT_MXT)
    list(APPEND SRCS sam_maxtouch.c sam_atmxtconfig.c)
  endif()
endif()

if(CONFIG_IEEE802154_MRF24J40)
  list(APPEND SRCS sam_mrf24j40.c)
endif()

if(CONFIG_LCD_ST7789)
  list(APPEND SRCS sam_st7789.c)
endif()

if(CONFIG_NET_OA_TC6)
  list(APPEND SRCS sam_oa_tc6.c)
endif()

target_sources(board PRIVATE ${SRCS})

if(EXISTS ${NUTTX_BOARD_DIR}/scripts/flash.ld.template)
  set_property(GLOBAL PROPERTY LD_SCRIPT
                               "${NUTTX_BOARD_DIR}/scripts/flash.ld.template")
else()
  set_property(GLOBAL PROPERTY LD_SCRIPT
                               "${NUTTX_COMMON_DIR}/scripts/flash.ld.template")
endif()
