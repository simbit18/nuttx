# ##############################################################################
# arch/arm/src/samv7/CMakeLists.txt
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

list(
  APPEND
  SRCS
  sam_start.c
  sam_clockconfig.c
  sam_irq.c
  sam_allocateheap.c
  sam_lowputc.c
  sam_serial.c
  sam_gpio.c
  sam_pck.c
  sam_uid.c
  sam_systemreset.c
  sam_chipid.c)

if(NOT CONFIG_SCHED_TICKLESS)
  list(APPEND SRCS sam_timerisr.c)
endif()

if(CONFIG_ARM_MPU)
  list(APPEND SRCS sam_mpuinit.c)
  if(CONFIG_BUILD_PROTECTED)
    list(APPEND SRCS sam_userspace.c)
  endif()
endif()

if(CONFIG_SAMV7_GPIO_IRQ)
  list(APPEND SRCS sam_gpioirq.c)
endif()

if(CONFIG_SAMV7_XDMAC)
  list(APPEND SRCS sam_xdmac.c)
endif()

if(CONFIG_SAMV7_WDT)
  list(APPEND SRCS sam_wdt.c)
endif()

if(CONFIG_SAMV7_RSWDT)
  list(APPEND SRCS sam_rswdt.c)
endif()

if(CONFIG_SAMV7_1WIREDRIVER)
  list(APPEND SRCS sam_1wire.c)
endif()

if(CONFIG_SAMV7_LIN_SOCKET)
  list(APPEND SRCS sam_lin_sock.c)
endif()

if(CONFIG_SAMV7_USART_IS_SPI_MASTER)
  list(APPEND SRCS sam_serial_spi.c)
endif()

if(CONFIG_SAMV7_SPI_MASTER)
  list(APPEND SRCS sam_spi.c)
endif()

if(CONFIG_SAMV7_SPI_SLAVE)
  list(APPEND SRCS sam_spi_slave.c)
endif()

if(CONFIG_SAMV7_QSPI_SPI_MODE)
  list(APPEND SRCS sam_qspi_spi.c)
elseif(CONFIG_SAMV7_QSPI)
  list(APPEND SRCS sam_qspi.c)
endif()

if(CONFIG_SAMV7_TWIHS0)
  list(APPEND SRCS sam_twihs.c)
elseif(CONFIG_SAMV7_TWIHS1)
  list(APPEND SRCS sam_twihs.c)
elseif(CONFIG_SAMV7_TWIHS2)
  list(APPEND SRCS sam_twihs.c)
endif()

if(CONFIG_SAMV7_SSC)
  list(APPEND SRCS sam_ssc.c)
endif()

if(CONFIG_SAMV7_HAVE_TC)
  list(APPEND SRCS sam_tc.c)
  if(CONFIG_TIMER)
    list(APPEND SRCS sam_tc_lowerhalf.c)
  endif()
  if(CONFIG_SAMV7_ONESHOT)
    list(APPEND SRCS sam_oneshot.c sam_oneshot_lowerhalf.c)
  endif()
  if(CONFIG_SAMV7_FREERUN)
    list(APPEND SRCS sam_freerun.c)
  endif()
  if(CONFIG_SCHED_TICKLESS)
    list(APPEND SRCS sam_tickless.c)
  endif()
  if(CONFIG_SAMV7_QENCODER)
    list(APPEND SRCS sam_qencoder.c)
  endif()
endif()

if(CONFIG_SAMV7_HSMCI)
  list(APPEND SRCS sam_hsmci.c sam_hsmci_clkdiv.c)
endif()

if(CONFIG_SAMV7_EMAC)
  list(APPEND SRCS sam_emac.c sam_ethernet.c)
endif()

if(CONFIG_SAMV7_MCAN)
  list(APPEND SRCS sam_mcan.c)
endif()

if(CONFIG_SAMV7_AFEC)
  list(APPEND SRCS sam_afec.c)
endif()

if(CONFIG_SAMV7_USBDEVHS)
  list(APPEND SRCS sam_usbdevhs.c)
endif()

if(CONFIG_SAMV7_TRNG)
  list(APPEND SRCS sam_trng.c)
endif()

if(CONFIG_SAMV7_EEFC)
  list(APPEND SRCS sam_eefc.c)
endif()

if(CONFIG_SAMV7_PROGMEM)
  list(APPEND SRCS sam_progmem.c)
endif()

if(CONFIG_SAMV7_USER_SIGNATURE)
  list(APPEND SRCS sam_us.c)
endif()

if(CONFIG_SAMV7_PWM)
  list(APPEND SRCS sam_pwm.c)
endif()

if(CONFIG_SAMV7_DAC)
  list(APPEND SRCS sam_dac.c)
endif()

target_sources(arch PRIVATE ${SRCS})
