# ##############################################################################
# boards/arm/samv7/same70-qmtech/src/CMakeLists.txt
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

if(CONFIG_SAMV7_SPI)
  list(APPEND SRCS sam_spi.c)
endif()

if(CONFIG_SAMV7_MCAN)
  list(APPEND SRCS sam_mcan.c)
endif()

if(CONFIG_SAMV7_AFEC)
  list(APPEND SRCS sam_afec.c)
endif()

if(CONFIG_SAMV7_DAC0 OR CONFIG_SAMV7_DAC1)
  list(APPEND SRCS sam_dac.c)
endif()

if(CONFIG_DEV_GPIO)
  list(APPEND SRCS sam_gpio.c)
endif()

target_sources(board PRIVATE ${SRCS})

if(EXISTS ${NUTTX_BOARD_DIR}/scripts/flash.ld.template)
  set_property(GLOBAL PROPERTY LD_SCRIPT
                               "${NUTTX_BOARD_DIR}/scripts/flash.ld.template")
else()
  set_property(GLOBAL PROPERTY LD_SCRIPT
                               "${NUTTX_COMMON_DIR}/scripts/flash.ld.template")
endif()
