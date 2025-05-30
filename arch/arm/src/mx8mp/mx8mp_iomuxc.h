/****************************************************************************
 * arch/arm/src/mx8mp/mx8mp_iomuxc.h
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

#ifndef __ARCH_ARM_SRC_MX8MP_MX8MP_IOMUXC_H
#define __ARCH_ARM_SRC_MX8MP_MX8MP_IOMUXC_H

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include <nuttx/config.h>
#include <stdint.h>
#include "hardware/mx8mp_pinmux.h"

/****************************************************************************
 * Public Function Prototypes
 ****************************************************************************/

/****************************************************************************
 * Name: mx8mp_iomuxc_set_pin_config
 *
 * Description:
 *   Configure the IOMUXC pin configuration.
 *   The first five parameters can be filled with the pin function ID macros.
 *
 ****************************************************************************/

void mx8mp_iomuxc_config(uint32_t mux_register,
                         uint32_t mux_mode,
                         uint32_t input_register,
                         uint32_t input_daisy,
                         uint32_t config_register,
                         uint32_t sion,
                         uint32_t config);

#endif /* __ARCH_ARM_SRC_MX8MP_MX8MP_IOMUXC_H */
