/****************************************************************************
 * boards/arm/stm32/b-g431b-esc1/include/board.h
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 *  Licensed to the Apache Software Foundation (ASF) under one or more
 *  contributor license agreements.  See the NOTICE file distributed with
 *  this work for additional information regarding copyright ownership.  The
 *  ASF licenses this file to you under the Apache License, Version 2.0 (the
 *  "License"); you may not use this file except in compliance with the
 *  License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 *
 ****************************************************************************/

#ifndef __BOARDS_ARM_STM32_B_G431B_ESC1_INCLUDE_BOARD_H
#define __BOARDS_ARM_STM32_B_G431B_ESC1_INCLUDE_BOARD_H

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include <nuttx/config.h>

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

/* Clocking *****************************************************************/

#define STM32_BOARD_XTAL               8000000             /* 8MHz */

#define STM32_HSI_FREQUENCY            16000000ul          /* 16MHz */
#define STM32_LSI_FREQUENCY            32000               /* 32kHz */
#define STM32_HSE_FREQUENCY            STM32_BOARD_XTAL    /* Y2 on board */
#undef STM32_LSE_FREQUENCY                                 /* Not available on this board */

#ifdef CONFIG_BOARD_STM32_BG431BESC1_USE_HSI

/* Main PLL Configuration.
 *
 * PLL source is HSI = 16MHz
 * PLLN = 85, PLLM = 4, PLLP = 10, PLLQ = 2, PLLR = 2
 *
 * f(VCO Clock) = f(PLL Clock Input) x (PLLN / PLLM)
 * f(PLL_P) = f(VCO Clock) / PLLP
 * f(PLL_Q) = f(VCO Clock) / PLLQ
 * f(PLL_R) = f(VCO Clock) / PLLR
 *
 * Where:
 * 8 <= PLLN <= 127
 * 1 <= PLLM <= 16
 * PLLP = 2 through 31
 * PLLQ = 2, 4, 6, or 8
 * PLLR = 2, 4, 6, or 8
 *
 * Do not exceed 170MHz on f(PLL_P), f(PLL_Q), or f(PLL_R).
 * 64MHz <= f(VCO Clock) <= 344MHz.
 *
 * Given the above:
 *
 * f(VCO Clock) = HSI   x PLLN / PLLM
 *              = 16MHz x 85   / 4
 *              = 340MHz
 *
 * PLLPCLK      = f(VCO Clock) / PLLP
 *              = 340MHz       / 10
 *              = 34MHz
 *                (May be used for ADC)
 *
 * PLLQCLK      = f(VCO Clock) / PLLQ
 *              = 340MHz       / 2
 *              = 170MHz
 *                (May be used for QUADSPI, FDCAN, SAI1, I2S3. If set to
 *                48MHz, may be used for USB, RNG.)
 *
 * PLLRCLK      = f(VCO Clock) / PLLR
 *              = 340MHz       / 2
 *              = 170MHz
 *                (May be used for SYSCLK and most peripherals.)
 */

#define STM32_PLLCFGR_PLLSRC           RCC_PLLCFGR_PLLSRC_HSI
#define STM32_PLLCFGR_PLLCFG           (RCC_PLLCFGR_PLLPEN | \
                                       RCC_PLLCFGR_PLLQEN | \
                                       RCC_PLLCFGR_PLLREN)

#define STM32_PLLCFGR_PLLN             RCC_PLLCFGR_PLLN(85)
#define STM32_PLLCFGR_PLLM             RCC_PLLCFGR_PLLM(4)
#define STM32_PLLCFGR_PLLP             RCC_PLLCFGR_PLLPDIV(10)
#define STM32_PLLCFGR_PLLQ             RCC_PLLCFGR_PLLQ_2
#define STM32_PLLCFGR_PLLR             RCC_PLLCFGR_PLLR_2

#define STM32_VCO_FREQUENCY            ((STM32_HSI_FREQUENCY / 4) * 85)
#define STM32_PLLP_FREQUENCY           (STM32_VCO_FREQUENCY / 10)
#define STM32_PLLQ_FREQUENCY           (STM32_VCO_FREQUENCY / 2)
#define STM32_PLLR_FREQUENCY           (STM32_VCO_FREQUENCY / 2)

/* Use the PLL and set the SYSCLK source to be PLLR (170MHz) */

#define STM32_SYSCLK_SW                RCC_CFGR_SW_PLL
#define STM32_SYSCLK_SWS               RCC_CFGR_SWS_PLL
#define STM32_SYSCLK_FREQUENCY         STM32_PLLR_FREQUENCY

/* AHB clock (HCLK) is SYSCLK (170MHz) */

#define STM32_RCC_CFGR_HPRE            RCC_CFGR_HPRE_SYSCLK
#define STM32_HCLK_FREQUENCY           STM32_SYSCLK_FREQUENCY

/* APB1 clock (PCLK1) is HCLK (170MHz) */

#define STM32_RCC_CFGR_PPRE1           RCC_CFGR_PPRE1_HCLK
#define STM32_PCLK1_FREQUENCY          STM32_HCLK_FREQUENCY

/* APB2 clock (PCLK2) is HCLK (170MHz) */

#define STM32_RCC_CFGR_PPRE2           RCC_CFGR_PPRE2_HCLK
#define STM32_PCLK2_FREQUENCY          STM32_HCLK_FREQUENCY

#endif /* CONFIG_BOARD_STM32_BG431BESC1_USE_HSI */

#ifdef CONFIG_BOARD_STM32_BG431BESC1_USE_HSE

/* Main PLL Configuration.
 *
 * PLL source is HSE = 8MHz
 * PLLN = 85, PLLM = 2, PLLP = 10, PLLQ = 2, PLLR = 2
 *
 * f(VCO Clock) = f(PLL Clock Input) x (PLLN / PLLM)
 * f(PLL_P) = f(VCO Clock) / PLLP
 * f(PLL_Q) = f(VCO Clock) / PLLQ
 * f(PLL_R) = f(VCO Clock) / PLLR
 *
 * Where:
 * 8 <= PLLN <= 127
 * 1 <= PLLM <= 16
 * PLLP = 2 through 31
 * PLLQ = 2, 4, 6, or 8
 * PLLR = 2, 4, 6, or 8
 *
 * Do not exceed 170MHz on f(PLL_P), f(PLL_Q), or f(PLL_R).
 * 64MHz <= f(VCO Clock) <= 344MHz.
 *
 * Given the above:
 *
 * f(VCO Clock) = HSI   x PLLN / PLLM
 *              = 8MHz x 85   / 2
 *              = 340MHz
 *
 * PLLPCLK      = f(VCO Clock) / PLLP
 *              = 340MHz       / 10
 *              = 34MHz
 *                (May be used for ADC)
 *
 * PLLQCLK      = f(VCO Clock) / PLLQ
 *              = 340MHz       / 2
 *              = 170MHz
 *                (May be used for QUADSPI, FDCAN, SAI1, I2S3. If set to
 *                48MHz, may be used for USB, RNG.)
 *
 * PLLRCLK      = f(VCO Clock) / PLLR
 *              = 340MHz       / 2
 *              = 170MHz
 *                (May be used for SYSCLK and most peripherals.)
 */

#define STM32_PLLCFGR_PLLSRC           RCC_PLLCFGR_PLLSRC_HSE
#define STM32_PLLCFGR_PLLCFG           (RCC_PLLCFGR_PLLPEN | \
                                       RCC_PLLCFGR_PLLQEN | \
                                       RCC_PLLCFGR_PLLREN)

#define STM32_PLLCFGR_PLLN             RCC_PLLCFGR_PLLN(85)
#define STM32_PLLCFGR_PLLM             RCC_PLLCFGR_PLLM(2)
#define STM32_PLLCFGR_PLLP             RCC_PLLCFGR_PLLPDIV(10)
#define STM32_PLLCFGR_PLLQ             RCC_PLLCFGR_PLLQ_2
#define STM32_PLLCFGR_PLLR             RCC_PLLCFGR_PLLR_2

#define STM32_VCO_FREQUENCY            ((STM32_HSI_FREQUENCY / 4) * 85)
#define STM32_PLLP_FREQUENCY           (STM32_VCO_FREQUENCY / 10)
#define STM32_PLLQ_FREQUENCY           (STM32_VCO_FREQUENCY / 2)
#define STM32_PLLR_FREQUENCY           (STM32_VCO_FREQUENCY / 2)

/* Use the PLL and set the SYSCLK source to be PLLR (170MHz) */

#define STM32_SYSCLK_SW                RCC_CFGR_SW_PLL
#define STM32_SYSCLK_SWS               RCC_CFGR_SWS_PLL
#define STM32_SYSCLK_FREQUENCY         STM32_PLLR_FREQUENCY

/* AHB clock (HCLK) is SYSCLK (170MHz) */

#define STM32_RCC_CFGR_HPRE            RCC_CFGR_HPRE_SYSCLK
#define STM32_HCLK_FREQUENCY           STM32_SYSCLK_FREQUENCY

/* APB1 clock (PCLK1) is HCLK (170MHz) */

#define STM32_RCC_CFGR_PPRE1           RCC_CFGR_PPRE1_HCLK
#define STM32_PCLK1_FREQUENCY          STM32_HCLK_FREQUENCY

/* APB2 clock (PCLK2) is HCLK (170MHz) */

#define STM32_RCC_CFGR_PPRE2           RCC_CFGR_PPRE2_HCLK
#define STM32_PCLK2_FREQUENCY          STM32_HCLK_FREQUENCY

#endif /* CONFIG_BOARD_STM32_BG431BESC1_USE_HSE */

/* APB2 timers 1, 8, 20 and 15-17 will receive PCLK2. */

/* Timers driven from APB2 will be PCLK2 */

#define STM32_APB2_TIM1_CLKIN   (STM32_PCLK2_FREQUENCY)
#define STM32_APB2_TIM8_CLKIN   (STM32_PCLK2_FREQUENCY)
#define STM32_APB1_TIM15_CLKIN  (STM32_PCLK2_FREQUENCY)
#define STM32_APB1_TIM16_CLKIN  (STM32_PCLK2_FREQUENCY)
#define STM32_APB1_TIM17_CLKIN  (STM32_PCLK2_FREQUENCY)

/* APB1 timers 2-7 will be twice PCLK1 */

#define STM32_APB1_TIM2_CLKIN   (STM32_PCLK1_FREQUENCY)
#define STM32_APB1_TIM3_CLKIN   (STM32_PCLK1_FREQUENCY)
#define STM32_APB1_TIM4_CLKIN   (STM32_PCLK1_FREQUENCY)
#define STM32_APB1_TIM6_CLKIN   (STM32_PCLK1_FREQUENCY)
#define STM32_APB1_TIM7_CLKIN   (STM32_PCLK1_FREQUENCY)

/* USB divider -- Divide PLL clock by 1.5 */

#define STM32_CFGR_USBPRE       0

/* Timer Frequencies, if APBx is set to 1, frequency is same to APBx
 * otherwise frequency is 2xAPBx.
 */

#define BOARD_TIM1_FREQUENCY   (STM32_PCLK2_FREQUENCY)
#define BOARD_TIM2_FREQUENCY   (STM32_PCLK1_FREQUENCY)
#define BOARD_TIM3_FREQUENCY   (STM32_PCLK1_FREQUENCY)
#define BOARD_TIM4_FREQUENCY   (STM32_PCLK1_FREQUENCY)
#define BOARD_TIM5_FREQUENCY   (STM32_PCLK1_FREQUENCY)
#define BOARD_TIM6_FREQUENCY   (STM32_PCLK1_FREQUENCY)
#define BOARD_TIM7_FREQUENCY   (STM32_PCLK1_FREQUENCY)
#define BOARD_TIM8_FREQUENCY   (STM32_PCLK2_FREQUENCY)
#define BOARD_TIM15_FREQUENCY  (STM32_PCLK2_FREQUENCY)
#define BOARD_TIM16_FREQUENCY  (STM32_PCLK2_FREQUENCY)
#define BOARD_TIM17_FREQUENCY  (STM32_PCLK2_FREQUENCY)
#define BOARD_TIM20_FREQUENCY  (STM32_PCLK2_FREQUENCY)

#ifdef CONFIG_STM32_FDCAN
#  ifdef CONFIG_BOARD_STM32_BG431BESC1_USE_HSE
#    define STM32_CCIPR_FDCANSRC   (RCC_CCIPR_FDCANSEL_HSE)
#    define STM32_FDCAN_FREQUENCY  (STM32_HSE_FREQUENCY)
#  else
#    error For now FDCAN supported only if HSE enabled
#  endif
#endif

/* LED definitions **********************************************************/

/* The B-G431B-ESC1 has four user LEDs.
 *
 * If CONFIG_ARCH_LEDS is not defined, then the user can control the LEDs in
 * any way.  The following definitions are used to access individual LEDs.
 */

/* LED index values for use with board_userled() */

#define BOARD_LED1                     0 /* User LD2 */
#define BOARD_NLEDS                    1

/* LED bits for use with board_userled_all() */

#define BOARD_LED1_BIT                 (1 << BOARD_LED1)

/* If CONFIG_ARCH_LEDs is defined, then NuttX will control the LED on board
 * the Nucleo G431RB.  The following definitions describe how NuttX controls
 * the LED:
 *
 *   SYMBOL              Meaning                  LED1 state
 *   ------------------  -----------------------  ----------
 *   LED_STARTED         NuttX has been started   OFF
 *   LED_HEAPALLOCATE    Heap has been allocated  OFF
 *   LED_IRQSENABLED     Interrupts enabled       OFF
 *   LED_STACKCREATED    Idle stack created       ON
 *   LED_INIRQ           In an interrupt          No change
 *   LED_SIGNAL          In a signal handler      No change
 *   LED_ASSERTION       An assertion failed      No change
 *   LED_PANIC           The system has crashed   Blinking
 *   LED_IDLE            STM32 is is sleep mode   Not used
 */

#define LED_STARTED      0
#define LED_HEAPALLOCATE 0
#define LED_IRQSENABLED  0
#define LED_STACKCREATED 1
#define LED_INIRQ        2
#define LED_SIGNAL       2
#define LED_ASSERTION    2
#define LED_PANIC        1

/* Button definitions *******************************************************/

/* The B-G431B-ESC supports one buttons controllabe by software:
 *
 *   B1 USER:  user button connected to the I/O PC10.
 */

#define BUTTON_USER      0
#define NUM_BUTTONS      1

#define BUTTON_USER_BIT  (1 << BUTTON_USER)

/* Alternate function pin selections ****************************************/

/* ADC1 */

#define GPIO_ADC1_IN1   GPIO_ADC1_IN1_0   /* PA0 */
#define GPIO_ADC1_IN2   GPIO_ADC1_IN2_0   /* PA1 */
#define GPIO_ADC1_IN3   GPIO_ADC1_IN3_0   /* PA2 */
#define GPIO_ADC1_IN4   GPIO_ADC1_IN4_0   /* PA3 */
#define GPIO_ADC1_IN5   GPIO_ADC1_IN5_0   /* PB14 */
#define GPIO_ADC1_IN10  GPIO_ADC1_IN10_0  /* PF0 */
#define GPIO_ADC1_IN11  GPIO_ADC1_IN11_0  /* PB12 */
#define GPIO_ADC1_IN12  GPIO_ADC1_IN12_0  /* PB1 */
#define GPIO_ADC1_IN14  GPIO_ADC1_IN14_0  /* PB11 */
#define GPIO_ADC1_IN15  GPIO_ADC1_IN15_0  /* PB0 */

/* USART2 (ST LINK Virtual Console and J3 pads) */

#define GPIO_USART2_TX     GPIO_USART2_TX_3 /* PB3 */
#define GPIO_USART2_RX     GPIO_USART2_RX_3 /* PB4 */

/* TIM1 configuration *******************************************************/

#define GPIO_TIM1_CH1OUT   (GPIO_TIM1_CH1OUT_0 | GPIO_SPEED_50MHz)  /* TIM1 CH1 - PA8  - U high */
#define GPIO_TIM1_CH2OUT   (GPIO_TIM1_CH2OUT_0 | GPIO_SPEED_50MHz)  /* TIM1 CH2 - PA9  - V high */
#define GPIO_TIM1_CH3OUT   (GPIO_TIM1_CH3OUT_0 | GPIO_SPEED_50MHz)  /* TIM1 CH3 - PA10 - W high */
#define GPIO_TIM1_CH1NOUT  (GPIO_TIM1_CH1NOUT_4 | GPIO_SPEED_50MHz) /* TIM1 CH1N - PC13 - U low */
#define GPIO_TIM1_CH2NOUT  (GPIO_TIM1_CH2NOUT_1 | GPIO_SPEED_50MHz) /* TIM1 CH2N - PA12 - V low */
#define GPIO_TIM1_CH3NOUT  (GPIO_TIM1_CH3NOUT_3 | GPIO_SPEED_50MHz) /* TIM1 CH3N - PB15 - W low */

/* TIM4 QE configuration ****************************************************/

#define GPIO_TIM4_CH1IN  (GPIO_TIM4_CH1IN_2 | GPIO_SPEED_50MHz) /* TIM4 CH1 - PB6 */
#define GPIO_TIM4_CH2IN  (GPIO_TIM4_CH2IN_2 | GPIO_SPEED_50MHz) /* TIM4 CH2 - PB7 */

/* OPAMP configuration ******************************************************/

#define GPIO_OPAMP1_VINM0  (GPIO_OPAMP1_VINM0_0) /* PA3 */
#define GPIO_OPAMP1_VINP0  (GPIO_OPAMP1_VINP0_0) /* PA1 */
#define GPIO_OPAMP1_VOUT   (GPIO_OPAMP1_VOUT_0)  /* PA2 */

#define GPIO_OPAMP2_VINM0  (GPIO_OPAMP2_VINM0_0) /* PA5 */
#define GPIO_OPAMP2_VINP0  (GPIO_OPAMP2_VINP0_0) /* PA7 */
#define GPIO_OPAMP2_VOUT   (GPIO_OPAMP2_VOUT_0)  /* PA6 */

#define GPIO_OPAMP3_VINM0  (GPIO_OPAMP3_VINM0_0) /* PB2 */
#define GPIO_OPAMP3_VINP0  (GPIO_OPAMP3_VINP0_0) /* PB0 */
#define GPIO_OPAMP3_VOUT   (GPIO_OPAMP3_VOUT_0)  /* PB1 */

/* CAN configuration ********************************************************/

#define GPIO_FDCAN1_RX (GPIO_FDCAN1_RX_1 | GPIO_SPEED_50MHz) /* PA11 */
#define GPIO_FDCAN1_TX (GPIO_FDCAN1_TX_2 | GPIO_SPEED_50MHz) /* PB9 */

/* DMA channels *************************************************************/

/* ADC */

#define ADC1_DMA_CHAN DMAMAP_DMA12_ADC1_0     /* DMA1 */

/* USART2 */

#define DMACHAN_USART2_TX DMAMAP_DMA12_USART2TX_0 /* DMA1 */
#define DMACHAN_USART2_RX DMAMAP_DMA12_USART2RX_0 /* DMA1 */

#endif /* __BOARDS_ARM_STM32_B_G431B_ESC1_INCLUDE_BOARD_H */
