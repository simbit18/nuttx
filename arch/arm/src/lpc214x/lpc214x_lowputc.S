/**************************************************************************
 * arch/arm/src/lpc214x/lpc214X_lowputc.S
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
 **************************************************************************/

/**************************************************************************
 * Included Files
 **************************************************************************/

#include <nuttx/config.h>

#include "chip.h"

#include "lpc214x_pinsel.h"
#include "lpc214x_uart.h"

/**************************************************************************
 * Pre-processor Definitions
 **************************************************************************/

#if defined(CONFIG_UART0_SERIAL_CONSOLE)
#  define LPC214X_UART_BASE    LPC214X_UART0_BASE
#  define LPC214X_UART_PINSEL  LPC214X_UART0_PINSEL
#  define LPC214X_UART_PINMASK LPC214X_UART0_PINMASK
#  define LPC214X_UART_BAUD    CONFIG_UART0_BAUD
#  define LPC214X_UART_BITS    CONFIG_UART0_BITS
#  define LPC214X_UART_PARITY  CONFIG_UART0_PARITY
#  define LPC214X_UART_2STOP   CONFIG_UART0_2STOP
#elif defined(CONFIG_UART1_SERIAL_CONSOLE)
#  define LPC214X_UART_BASE    LPC214X_UART1_BASE
#  define LPC214X_UART_PINSEL  LPC214X_UART1_PINSEL
#  define LPC214X_UART_PINMASK LPC214X_UART1_PINMASK
#  define LPC214X_UART_BAUD    CONFIG_UART1_BAUD
#  define LPC214X_UART_BITS    CONFIG_UART1_BITS
#  define LPC214X_UART_PARITY  CONFIG_UART1_PARITY
#  define LPC214X_UART_2STOP   CONFIG_UART1_2STOP
#else
#  error "No CONFIG_UARTn_SERIAL_CONSOLE Setting"
#endif

#if LPC214X_UART_BITS == 5
#  define LPC214X_LCR_CHAR LPC214X_LCR_CHAR_5
#elif LPC214X_UART_BITS == 6
#  define LPC214X_LCR_CHAR LPC214X_LCR_CHAR_6
#elif LPC214X_UART_BITS == 7
#  define LPC214X_LCR_CHAR LPC214X_LCR_CHAR_7
#elif LPC214X_UART_BITS == 8
#  define LPC214X_LCR_CHAR LPC214X_LCR_CHAR_8
#else
#  error "No CONFIG_UARTn_BITS Setting"
#endif

#if LPC214X_UART_PARITY == 0
#  define LPC214X_LCR_PAR LPC214X_LCR_PAR_NONE
#elif LPC214X_UART_PARITY == 1
#  define LPC214X_LCR_PAR LPC214X_LCR_PAR_ODD
#elif LPC214X_UART_PARITY == 2
#  define LPC214X_LCR_PAR LPC214X_LCR_PAR_EVEN
#elif LPC214X_UART_PARITY == 3
#  define LPC214X_LCR_PAR LPC214X_LCR_PAR_MARK
#elif LPC214X_UART_PARITY == 4
#  define LPC214X_LCR_PAR LPC214X_LCR_PAR_SPACE
#else
#  error "No CONFIG_UARTn_PARITY Setting"
#endif

#if LPC214X_UART_2STOP != 0
#  define LPC214X_LCR_STOP LPC214X_LCR_STOP_2
#else
#  define LPC214X_LCR_STOP LPC214X_LCR_STOP_1
#endif

#define LPC214X_LCR_VALUE (LPC214X_LCR_CHAR | LPC214X_LCR_PAR | LPC214X_LCR_STOP)
#define LPC214X_FCR_VALUE (LPC214X_FCR_FIFO_TRIG8 | LPC214X_FCR_TX_FIFO_RESET |\
                           LPC214X_FCR_RX_FIFO_RESET | LPC214X_FCR_FIFO_ENABLE)

/**************************************************************************
 * Private Types
 **************************************************************************/

/**************************************************************************
 * Private Function Prototypes
 **************************************************************************/

/**************************************************************************
 * Public Data
 **************************************************************************/

/**************************************************************************
 * Private Data
 **************************************************************************/

/**************************************************************************
 * Private Functions
 **************************************************************************/

/**************************************************************************
 * Public Functions
 **************************************************************************/

/**************************************************************************
 * Name: arm_lowputc
 **************************************************************************/

/* This assembly language version has the advantage that it can does not
 * require a C stack and uses only r0-r1.  Hence it can be used during
 * early boot phases.
 */

	.text
	.global	arm_lowputc
	.type	arm_lowputc, function
arm_lowputc:
	/* On entry, r0 holds the character to be printed */

	ldr	r1, =LPC214X_UART_BASE
	strb	r0, [r1, #LPC214X_UART_THR_OFFSET]

	/* Wait for the byte to be transferred */

1:	ldr	r0, [r1, #LPC214X_UART_LSR_OFFSET]
	ands	r0, #LPC214X_LSR_TEMT  /* Transmitter empty */
	beq	1b

	/* And return */

	mov	pc, lr
	.size	arm_lowputc, . - arm_lowputc

/* This performs basic initialization of the UART.  This can be called very
 * early in initialization because it does not depend on having a stack.  It
 * modifies r0-r2 and r14.
 */

	.text
	.globl	up_lowsetup
	.type	up_lowsetup, function
up_lowsetup:
	/* Configure PINSEL0 */

	ldr	r0, =LPC214X_PINSEL0
	ldr	r1, [r0]
	ldr	r2, =~LPC214X_UART_PINMASK
	and	r1, r2
	ldr	r2, =LPC214X_UART_PINSEL
	orr	r1, r2
	str	r1, [r0]

	/* Configure parity, data bits, stop bits and set DLAB=1 */

	ldr	r0, =LPC214X_UART_BASE
	mov	r1, #(LPC214X_LCR_VALUE | LPC214X_LCR_DLAB_ENABLE)
	strb	r1, [r0, #LPC214X_UART_LCR_OFFSET]

	/* Set the BAUD divisor */

	mov	r1, #(UART_BAUD(LPC214X_UART_BAUD) >> 8)
	strb	r1, [r0, #LPC214X_UART_DLM_OFFSET]

	mov	r1, #(UART_BAUD(LPC214X_UART_BAUD) & 0xff)
	strb	r1, [r0, #LPC214X_UART_DLL_OFFSET]

	/* Clear DLAB */

	mov	r1, #LPC214X_LCR_VALUE
	strb	r1, [r0, #LPC214X_UART_LCR_OFFSET]

	/* Configure the FIFOs */

	mov	r1, #LPC214X_FCR_VALUE
	strb	r1, [r0, #LPC214X_UART_FCR_OFFSET]

	/* And return */

	mov	pc, lr
	.size	up_lowsetup, . - up_lowsetup
	.end
