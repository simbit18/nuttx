/****************************************************************************
 * arch/arm/src/xmc4/xmc4_lowputc.c
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.  The
 * ASF licenses this file to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
 * License for the specific language governing permissions and limitations
 * under the License.
 *
 ****************************************************************************/

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include <nuttx/config.h>
#include <nuttx/lib/math32.h>

#include <stdint.h>
#include <errno.h>

#include <arch/irq.h>
#include <arch/board/board.h>

#include "arm_internal.h"

#include <assert.h>
#include <debug.h>

#include "xmc4_config.h"
#include "hardware/xmc4_usic.h"
#include "hardware/xmc4_ports.h"
#include "hardware/xmc4_pinmux.h"
#include "xmc4_usic.h"
#include "xmc4_gpio.h"
#include "xmc4_lowputc.h"

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

/* Select UART parameters for the selected console */

#if defined(HAVE_UART_CONSOLE)
#  if defined(CONFIG_UART0_SERIAL_CONSOLE)
#    define CONSOLE_CHAN     USIC0_CHAN0
#    define CONSOLE_FREQ     BOARD_CORECLK_FREQ
#    define CONSOLE_DX       BOARD_UART0_DX
#    define CONSOLE_BAUD     CONFIG_UART0_BAUD
#    define CONSOLE_BITS     CONFIG_UART0_BITS
#    define CONSOLE_2STOP    CONFIG_UART0_2STOP
#    define CONSOLE_PARITY   CONFIG_UART0_PARITY
#  elif defined(CONFIG_UART1_SERIAL_CONSOLE)
#    define CONSOLE_CHAN     USIC0_CHAN1
#    define CONSOLE_FREQ     BOARD_CORECLK_FREQ
#    define CONSOLE_DX       BOARD_UART1_DX
#    define CONSOLE_BAUD     CONFIG_UART1_BAUD
#    define CONSOLE_BITS     CONFIG_UART1_BITS
#    define CONSOLE_2STOP    CONFIG_UART1_2STOP
#    define CONSOLE_PARITY   CONFIG_UART1_PARITY
#  elif defined(CONFIG_UART2_SERIAL_CONSOLE)
#    define CONSOLE_CHAN     USIC1_CHAN0
#    define CONSOLE_FREQ     BOARD_BUS_FREQ
#    define CONSOLE_DX       BOARD_UART2_DX
#    define CONSOLE_BAUD     CONFIG_UART2_BAUD
#    define CONSOLE_BITS     CONFIG_UART2_BITS
#    define CONSOLE_2STOP    CONFIG_UART2_2STOP
#    define CONSOLE_PARITY   CONFIG_UART2_PARITY
#  elif defined(CONFIG_UART3_SERIAL_CONSOLE)
#    define CONSOLE_CHAN     USIC1_CHAN1
#    define CONSOLE_FREQ     BOARD_BUS_FREQ
#    define CONSOLE_DX       BOARD_UART3_DX
#    define CONSOLE_BAUD     CONFIG_UART3_BAUD
#    define CONSOLE_BITS     CONFIG_UART3_BITS
#    define CONSOLE_2STOP    CONFIG_UART3_2STOP
#    define CONSOLE_PARITY   CONFIG_UART3_PARITY
#  elif defined(CONFIG_UART4_SERIAL_CONSOLE)
#    define CONSOLE_CHAN     USIC2_CHAN0
#    define CONSOLE_FREQ     BOARD_BUS_FREQ
#    define CONSOLE_DX       BOARD_UART4_DX
#    define CONSOLE_BAUD     CONFIG_UART4_BAUD
#    define CONSOLE_BITS     CONFIG_UART4_BITS
#    define CONSOLE_2STOP    CONFIG_UART4_2STOP
#    define CONSOLE_PARITY   CONFIG_UART4_PARITY
#  elif defined(CONFIG_UART5_SERIAL_CONSOLE)
#    define CONSOLE_CHAN     USIC2_CHAN1
#    define CONSOLE_FREQ     BOARD_BUS_FREQ
#    define CONSOLE_DX       BOARD_UART5_DX
#    define CONSOLE_BAUD     CONFIG_UART5_BAUD
#    define CONSOLE_BITS     CONFIG_UART5_BITS
#    define CONSOLE_2STOP    CONFIG_UART5_2STOP
#    define CONSOLE_PARITY   CONFIG_UART5_PARITY
#  elif defined(HAVE_UART_CONSOLE)
#    error "No CONFIG_UARTn_SERIAL_CONSOLE Setting"
#  endif
#endif /* HAVE_UART_CONSOLE */

/* REVISIT: Oversampling is hardcoded to 16 here.  Perhaps this should be in
 * the config structure.
 */

#define UART_OVERSAMPLING    16

#if defined(CONFIG_XMC4_USIC0_CHAN0_ISUART)
#if CONFIG_XMC4_USIC0_CHAN0_TX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC0_CHAN0_TX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC0_CHAN0_TX_BUFFER_SIZE)
#  error Tx Buffer Size should be a power of 2 between 2 and 64
#endif

#if CONFIG_XMC4_USIC0_CHAN0_RX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC0_CHAN0_RX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC0_CHAN0_RX_BUFFER_SIZE)
#  error Rx Buffer Size should be a power of 2 between 2 and 64
#endif

#endif

#if defined(CONFIG_XMC4_USIC0_CHAN1_ISUART)
#if CONFIG_XMC4_USIC0_CHAN1_TX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC0_CHAN1_TX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC0_CHAN1_TX_BUFFER_SIZE)
#  error Tx Buffer Size should be a power of 2 between 2 and 64
#endif

#if CONFIG_XMC4_USIC0_CHAN1_RX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC0_CHAN1_RX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC0_CHAN1_RX_BUFFER_SIZE)
#  error Rx Buffer Size should be a power of 2 between 2 and 64
#endif

#endif

#if defined(CONFIG_XMC4_USIC0_CHAN0_ISUART) && defined(CONFIG_XMC4_USIC0_CHAN1_ISUART)
#if CONFIG_XMC4_USIC0_CHAN0_TX_BUFFER_SIZE + CONFIG_XMC4_USIC0_CHAN0_RX_BUFFER_SIZE + \
    CONFIG_XMC4_USIC0_CHAN1_TX_BUFFER_SIZE + CONFIG_XMC4_USIC0_CHAN1_RX_BUFFER_SIZE > 64
#  error The sum of Rx and Tx Buffers sizes should be inferior to 64
#endif
#endif

#if defined(CONFIG_XMC4_USIC1_CHAN0_ISUART)
#if CONFIG_XMC4_USIC1_CHAN0_TX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC1_CHAN0_TX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC1_CHAN0_TX_BUFFER_SIZE)
#  error Tx Buffer Size should be a power of 2 between 2 and 64
#endif

#if CONFIG_XMC4_USIC1_CHAN0_RX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC1_CHAN0_RX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC1_CHAN0_RX_BUFFER_SIZE)
#  error Rx Buffer Size should be a power of 2 between 2 and 64
#endif

#if CONFIG_XMC4_USIC1_CHAN0_TX_BUFFER_SIZE + CONFIG_XMC4_USIC1_CHAN0_RX_BUFFER_SIZE > 64
#  error The sum of Rx and Tx Buffer sizes should be inferior to 64
#endif
#endif

#if defined(CONFIG_XMC4_USIC1_CHAN1_ISUART)
#if CONFIG_XMC4_USIC1_CHAN1_TX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC1_CHAN1_TX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC1_CHAN1_TX_BUFFER_SIZE)
#  error Tx Buffer Size should be a power of 2 between 2 and 64
#endif

#if CONFIG_XMC4_USIC1_CHAN1_RX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC1_CHAN1_RX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC1_CHAN1_RX_BUFFER_SIZE)
#  error Rx Buffer Size should be a power of 2 between 2 and 64
#endif

#if CONFIG_XMC4_USIC1_CHAN1_TX_BUFFER_SIZE + CONFIG_XMC4_USIC1_CHAN1_RX_BUFFER_SIZE > 64
#  error The sum of Rx and Tx Buffer sizes should be inferior to 64
#endif
#endif

#if defined(CONFIG_XMC4_USIC1_CHAN0_ISUART) && defined(CONFIG_XMC4_USIC1_CHAN1_ISUART)
#if CONFIG_XMC4_USIC1_CHAN0_TX_BUFFER_SIZE + CONFIG_XMC4_USIC1_CHAN0_RX_BUFFER_SIZE + \
    CONFIG_XMC4_USIC1_CHAN1_TX_BUFFER_SIZE + CONFIG_XMC4_USIC1_CHAN1_RX_BUFFER_SIZE > 64 
#  error The sum of Rx and Tx Buffers sizes should be inferior to 64
#endif
#endif

#if defined(CONFIG_XMC4_USIC2_CHAN0_ISUART)
#if CONFIG_XMC4_USIC2_CHAN0_TX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC2_CHAN0_TX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC2_CHAN0_TX_BUFFER_SIZE)
#  error Tx Buffer Size should be a power of 2 between 2 and 64
#endif

#if CONFIG_XMC4_USIC2_CHAN0_RX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC2_CHAN0_RX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC2_CHAN0_RX_BUFFER_SIZE)
#  error Rx Buffer Size should be a power of 2 between 2 and 64
#endif

#if CONFIG_XMC4_USIC2_CHAN0_TX_BUFFER_SIZE + CONFIG_XMC4_USIC2_CHAN0_RX_BUFFER_SIZE > 64
#  error The sum of Rx and Tx Buffer sizes should be inferior to 64
#endif
#endif

#if defined(CONFIG_XMC4_USIC2_CHAN1_ISUART)
#if CONFIG_XMC4_USIC2_CHAN1_TX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC2_CHAN1_TX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC2_CHAN1_TX_BUFFER_SIZE)
#  error Tx Buffer Size should be a power of 2 between 2 and 64
#endif

#if CONFIG_XMC4_USIC2_CHAN1_RX_BUFFER_SIZE < 2 \
    || CONFIG_XMC4_USIC2_CHAN1_RX_BUFFER_SIZE > 64 \
    || !IS_POWER_OF_2(CONFIG_XMC4_USIC2_CHAN1_RX_BUFFER_SIZE)
#  error Rx Buffer Size should be a power of 2 between 2 and 64
#endif

#if CONFIG_XMC4_USIC2_CHAN1_TX_BUFFER_SIZE + CONFIG_XMC4_USIC2_CHAN1_RX_BUFFER_SIZE > 64
#  error The sum of Rx and Tx Buffer sizes should be inferior to 64
#endif
#endif

#if defined(CONFIG_XMC4_USIC2_CHAN0_ISUART) && defined(CONFIG_XMC4_USIC2_CHAN1_ISUART)
#if CONFIG_XMC4_USIC2_CHAN0_TX_BUFFER_SIZE + CONFIG_XMC4_USIC2_CHAN0_RX_BUFFER_SIZE + \
    CONFIG_XMC4_USIC2_CHAN1_TX_BUFFER_SIZE + CONFIG_XMC4_USIC2_CHAN1_RX_BUFFER_SIZE > 64 
#  error The sum of Rx and Tx Buffers sizes should be inferior to 64
#endif
#endif

/****************************************************************************
 * Private Data
 ****************************************************************************/

#ifdef HAVE_UART_CONSOLE
static const struct uart_config_s g_console_config =
{
  .baud   = CONSOLE_BAUD,
  .dx     = CONSOLE_DX,
  .parity = CONSOLE_PARITY,
  .nbits  = CONSOLE_BITS,
  .stop2  = CONSOLE_2STOP
};
#endif

/****************************************************************************
 * Public Functions
 ****************************************************************************/

/****************************************************************************
 * Name: arm_lowputc
 *
 * Description:
 *   Output one byte on the serial console
 *
 ****************************************************************************/

void arm_lowputc(char ch)
{
#ifdef HAVE_UART_CONSOLE
  uintptr_t base;
  uint32_t regval;

  /* Get the base address of the USIC registers associated with this
   * channel
   */

  base = xmc4_channel_baseaddress(CONSOLE_CHAN);
  DEBUGASSERT(base != 0);

  /* Wait for the transmit buffer/fifo to be "not full." */

  do
    {
      regval = getreg32(base + XMC4_USIC_TRBSR_OFFSET);
    }
  while ((regval & USIC_TRBSR_TFULL) != 0);

  /* Then write the character to the USIC IN register */

  putreg32((uint32_t)ch, base + XMC4_USIC_IN_OFFSET);
#endif
}

/****************************************************************************
 * Name: xmc4_lowsetup
 *
 * Description:
 *   This performs basic initialization of the UART used for the serial
 *   console.  Its purpose is to get the console output available as soon
 *   as possible.
 *
 ****************************************************************************/

void xmc4_lowsetup(void)
{
#ifdef HAVE_UART_DEVICE
  /* Configure UART pins for the all enabled UARTs.
   *
   * NOTE that the board must provide the definitions in the board.h header
   * file of the form like:  GPIO_UARTn_RXm and GPIO_UARTn_TXm where n is
   * the USIC module, 0..(XMC_NUSIC-1), and m is the USIC channel number, 0
   * or 1.
   *
   * In additional, the board.h must provide the definition of
   * BOARD_BOARD_UARTn_DX which indicates which input pin is selected, i.e.
   * one of the 0=DXA, 1=DXB, ... 6=DXG.
   */

#ifdef HAVE_UART0
  xmc4_gpio_config(GPIO_UART0_RXD);
  xmc4_gpio_config(GPIO_UART0_TXD);
#endif
#ifdef HAVE_UART1
  xmc4_gpio_config(GPIO_UART1_RXD);
  xmc4_gpio_config(GPIO_UART1_TXD);
#endif
#ifdef HAVE_UART2
  xmc4_gpio_config(GPIO_UART2_RXD);
  xmc4_gpio_config(GPIO_UART2_TXD);
#endif
#ifdef HAVE_UART3
  xmc4_gpio_config(GPIO_UART3_RXD);
  xmc4_gpio_config(GPIO_UART3_TXD);
#endif
#ifdef HAVE_UART4
  xmc4_gpio_config(GPIO_UART4_RXD);
  xmc4_gpio_config(GPIO_UART4_TXD);
#endif
#ifdef HAVE_UART5
  xmc4_gpio_config(GPIO_UART5_RXD);
  xmc4_gpio_config(GPIO_UART5_TXD);
#endif

#ifdef HAVE_UART_CONSOLE
  /* Configure the console (only) now.  Other UARTs will be configured
   * when the serial driver is opened.
   */

  xmc4_uart_configure(CONSOLE_CHAN, &g_console_config);

#endif /* HAVE_UART_CONSOLE */
#endif /* HAVE_UART_DEVICE */
}

/****************************************************************************
 * Name: xmc4_uart_configure
 *
 * Description:
 *   Enable and configure a USIC channel as a RS-232 UART.
 *
 * Returned Value:
 *   Zero (OK) is returned on success; A negated errno value is returned to
 *   indicate the nature of any failure.
 *
 ****************************************************************************/

#ifdef HAVE_UART_DEVICE
int xmc4_uart_configure(enum usic_channel_e channel,
                        const struct uart_config_s *config)
{
  uintptr_t base;
  uint32_t regval;
  int ret;

  /* Get the base address of the USIC registers associated with this
   * channel
   */

  base = xmc4_channel_baseaddress(channel);
  if (base == 0)
    {
      return -EINVAL;
    }

  /* Enable the USIC channel */

  ret = xmc4_enable_usic_channel(channel);
  if (ret < 0)
    {
      return ret;
    }

  /* Configure the BAUD rate.
   * REVISIT: Oversample is hardcoded to 16 here.  Perhaps this should be in
   * the config structure.
   */

  ret = xmc4_usic_baudrate(channel, config->baud, UART_OVERSAMPLING);

  /* Configure frame format.
   *
   *   - Pulse length for standard UART signaling,  i.e. the 0 level is
   *     signaled during the complete bit time
   *   - Enable Sample Majority Decision sample mode
   */

  regval = USIC_PCR_ASCMODE_PLBIT | USIC_PCR_ASCMODE_SMD;

  /* Enable the receive and transmit status */

  regval |= USIC_PCR_ASCMODE_RSTEN | USIC_PCR_ASCMODE_TSTEN;

  /* Sampling point set equal to the half of the oversampling period */

  regval |= USIC_PCR_ASCMODE_SP((UART_OVERSAMPLING >> 1) + 1);

  /* Configure the number of stop bits */

  if (config->stop2)
    {
      regval |= USIC_PCR_ASCMODE_STPB;
    }

  putreg32(regval, base + XMC4_USIC_PCR_OFFSET);

  /* Configure Shift Control Register:
   *
   *   - Set passive data level, high
   *   - Transmission Mode: The shift control signal is considered active if
   *     it is at 1-level. This is the setting to be programmed to allow
   *     data transfers.
   *   - Set word length
   *   - Set frame length equal to the word length
   */

  regval = USIC_SCTR_PDL1 | USIC_SCTR_TRM_1LEVEL |
           USIC_SCTR_FLE(config->nbits) | USIC_SCTR_WLE(config->nbits);
  putreg32(regval, base + XMC4_USIC_SCTR_OFFSET);

  /* Enable transfer buffer */

  regval = USIC_TCSR_TDEN_TDIV | USIC_TCSR_TDSSM;
  putreg32(regval, base + XMC4_USIC_TCSR_OFFSET);

  /* Clear protocol status */

  putreg32(0xffffffff, base + XMC4_USIC_PSCR_OFFSET);

  /* Configure parity */

  if (config->parity == 1)
    {
      /* Odd parrity */

      regval = USIC_CCR_PM_ODD;
    }
  else if (config->parity == 2)
    {
      /* Even parity */

      regval = USIC_CCR_PM_EVEN;
    }
  else
    {
      /* No parity */

      DEBUGASSERT(config->parity == 0);
      regval = USIC_CCR_PM_NONE;
    }

  putreg32(regval, base + XMC4_USIC_CCR_OFFSET);

  /* Set DX0CR input source path */

  regval  = getreg32(base + XMC4_USIC_DX0CR_OFFSET);
  regval &= ~USIC_DXCR_DSEL_MASK;
  regval |= USIC_DXCR_DSEL_DX(config->dx);
  putreg32(regval, base + XMC4_USIC_DX0CR_OFFSET);

  /* Disable transmit FIFO */

  regval  = getreg32(base + XMC4_USIC_TBCTR_OFFSET);
  regval &= ~USIC_TBCTR_SIZE_MASK;
  putreg32(regval, base + XMC4_USIC_TBCTR_OFFSET);

  /* Configure transmit FIFO
   *
   *   - LIMIT = 1
   *   - STBTEN = 0, the trigger of the standard transmit buffer event is
   *     based on the transition of the fill level from equal to below the
   *     limit, not the fact being below
   *   - LOF = 0, A standard transmit buffer event occurs when the filling
   *     level equals the limit value and gets lower due to transmission of
   *     a data word
   */

  regval &= ~(USIC_TBCTR_DPTR_MASK | USIC_TBCTR_LIMIT_MASK |
              USIC_TBCTR_STBTEN | USIC_TBCTR_SIZE_MASK |
              USIC_TBCTR_LOF);
  regval |=  (USIC_TBCTR_DPTR(config->startbufferptr)) |
              USIC_TBCTR_LIMIT(1) |
              USIC_TBCTR_SIZE(config->txbuffersize);
  putreg32(regval, base + XMC4_USIC_TBCTR_OFFSET);

  /* Disable the receive FIFO */

  regval  = getreg32(base + XMC4_USIC_RBCTR_OFFSET);
  regval &= ~USIC_RBCTR_SIZE_MASK;
  putreg32(regval, base + XMC4_USIC_RBCTR_OFFSET);

  /* Configure receive FIFO.
   *
   *   - LOF = 1, A standard receive buffer event occurs when the filling
   *     level equals the limit value and gets bigger due to the reception
   *     of a new data word
   */

  regval &= ~(USIC_RBCTR_DPTR_MASK | USIC_RBCTR_LIMIT_MASK |
              USIC_RBCTR_SIZE_MASK);
  regval |= (USIC_RBCTR_DPTR(config->startbufferptr + config->txbuffersize) |
              USIC_RBCTR_LIMIT(config->rxbuffersize) |
              USIC_RBCTR_SIZE(config->rxbuffersize) |
             USIC_RBCTR_LOF);
  putreg32(regval, base + XMC4_USIC_RBCTR_OFFSET);

  /* Start UART */

  regval  = getreg32(base + XMC4_USIC_CCR_OFFSET);
  regval &= ~USIC_CCR_MODE_MASK;
  regval |= USIC_CCR_MODE_ASC;
  putreg32(regval, base + XMC4_USIC_CCR_OFFSET);

  /* Set service request for UART protocol, receiver, and transmitter events.
   *
   *   Set channel 0 events on service request 0
   *   Set channel 1 events on service request 1
   */

  regval  = getreg32(base + XMC4_USIC_INPR_OFFSET);
  regval &= ~(USIC_INPR_TBINP_MASK | USIC_INPR_RINP_MASK |
              USIC_INPR_AINP_MASK | USIC_INPR_PINP_MASK);

  if (((unsigned int)channel & 1) != 0)
    {
      regval |= (USIC_INPR_TBINP_SR1 | USIC_INPR_RINP_SR1 |
                 USIC_INPR_AINP_SR1 | USIC_INPR_PINP_SR1);
    }
  else
    {
      regval |= (USIC_INPR_TBINP_SR0 | USIC_INPR_RINP_SR0 |
                 USIC_INPR_AINP_SR0 | USIC_INPR_PINP_SR0);
    }

  putreg32(regval, base + XMC4_USIC_INPR_OFFSET);
  return OK;
}
#endif
