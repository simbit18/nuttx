/****************************************************************************
 * arch/risc-v/src/hpm6750/hpm6750_memorymap.h
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

#ifndef __ARCH_RISCV_SRC_HPM6750_HPM6750_MEMORYMAP_H
#define __ARCH_RISCV_SRC_HPM6750_HPM6750_MEMORYMAP_H

/****************************************************************************
 * Included Files
 ****************************************************************************/

#include "riscv_common_memorymap.h"
#include "hardware/hpm6750_memorymap.h"
#include "hardware/hpm6750_uart.h"
#include "hardware/hpm6750_mchtmr.h"
#include "hardware/hpm6750_ioc.h"
#include "hardware/hpm6750_plic.h"
#include "hardware/hpm6750_sysctl.h"

/****************************************************************************
 * Pre-processor Definitions
 ****************************************************************************/

/* Idle thread stack starts from _ebss */

#ifndef __ASSEMBLY__
#define HPM6750_IDLESTACK_BASE  (uintptr_t)_ebss
#else
#define HPM6750_IDLESTACK_BASE  _ebss
#endif

#define HPM6750_IDLESTACK_TOP  (HPM6750_IDLESTACK_BASE + SMP_STACK_SIZE)

#endif /* __ARCH_RISCV_SRC_HPM6750_HPM6750_MEMORYMAP_H */
