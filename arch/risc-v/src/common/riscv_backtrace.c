/****************************************************************************
 * arch/risc-v/src/common/riscv_backtrace.c
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
#include <nuttx/arch.h>
#include "sched/sched.h"
#include "riscv_internal.h"

/****************************************************************************
 * Private Functions
 ****************************************************************************/

/****************************************************************************
 * Name: getfp
 *
 * Description:
 *  getfp() returns current frame pointer
 *
 ****************************************************************************/

static inline uintptr_t getfp(void)
{
  register uintptr_t fp;

  __asm__
  (
    "\tadd  %0, x0, fp\n"
    : "=r"(fp)
  );

  return fp;
}

/****************************************************************************
 * Name: backtrace
 *
 * Description:
 *  backtrace() parsing the return address through frame pointer
 *
 ****************************************************************************/

nosanitize_address
static int backtrace(uintptr_t *base, uintptr_t *limit,
                     uintptr_t *fp, uintptr_t *ra,
                     void **buffer, int size, int *skip)
{
  int i = 0;
#if CONFIG_ARCH_INTERRUPTSTACK > 15
  int cpu = up_cpu_index();
  uintptr_t *intstack_limit =
    (uintptr_t *)((uintptr_t)g_intstacktop -
                  (CONFIG_ARCH_INTERRUPTSTACK * cpu));

  uintptr_t *intstack_base =
    (uintptr_t *)((uintptr_t)intstack_limit - CONFIG_ARCH_INTERRUPTSTACK);
#endif

  if (ra)
    {
      if ((*skip)-- <= 0)
        {
          buffer[i++] = ra;
        }
    }

  for (; i < size; fp = (uintptr_t *)*(fp - 2))
    {
      if ((fp > limit || fp < base)
#if CONFIG_ARCH_INTERRUPTSTACK > 15
          && (fp > intstack_limit || fp < intstack_base)
#endif
         )
        {
          break;
        }

      ra = (uintptr_t *)*(fp - 1);
      if (ra == NULL)
        {
          break;
        }

      if ((*skip)-- <= 0)
        {
          buffer[i++] = ra;
        }
    }

  return i;
}

/****************************************************************************
 * Public Functions
 ****************************************************************************/

/****************************************************************************
 * Name: up_backtrace
 *
 * Description:
 *  up_backtrace()  returns  a backtrace for the TCB, in the array
 *  pointed to by buffer.  A backtrace is the series of currently active
 *  function calls for the program.  Each item in the array pointed to by
 *  buffer is of type void *, and is the return address from the
 *  corresponding stack frame.  The size argument specifies the maximum
 *  number of addresses that can be stored in buffer.   If  the backtrace is
 *  larger than size, then the addresses corresponding to the size most
 *  recent function calls are returned; to obtain the complete backtrace,
 *  make sure that buffer and size are large enough.
 *
 * Input Parameters:
 *   tcb    - Address of the task's TCB
 *   buffer - Return address from the corresponding stack frame
 *   size   - Maximum number of addresses that can be stored in buffer
 *   skip   - number of addresses to be skipped
 *
 * Returned Value:
 *   up_backtrace() returns the number of addresses returned in buffer
 *
 * Assumptions:
 *   Have to make sure tcb keep safe during function executing, it means
 *   1. Tcb have to be self or not-running.  In SMP case, the running task
 *      PC & SP cannot be backtrace, as whose get from tcb is not the newest.
 *   2. Tcb have to keep not be freed.  In task exiting case, have to
 *      make sure the tcb get from pid and up_backtrace in one critical
 *      section procedure.
 *
 ****************************************************************************/

int up_backtrace(struct tcb_s *tcb, void **buffer, int size, int skip)
{
  struct tcb_s *rtcb = running_task();
  int ret;

  if (size <= 0 || !buffer)
    {
      return 0;
    }

  if (tcb == NULL || tcb == rtcb)
    {
      if (up_interrupt_context())
        {
          ret = backtrace(rtcb->stack_base_ptr,
                          (uintptr_t *)((uintptr_t)rtcb->stack_base_ptr +
                                        rtcb->adj_stack_size),
                          (void *)getfp(), NULL, buffer, size, &skip);
          if (ret < size)
            {
              ret += backtrace(rtcb->stack_base_ptr, (uintptr_t *)
                               ((uintptr_t)rtcb->stack_base_ptr +
                                rtcb->adj_stack_size),
                               running_regs()[REG_FP],
                               running_regs()[REG_EPC],
                               &buffer[ret], size - ret, &skip);
            }
        }
      else
        {
#ifdef CONFIG_ARCH_KERNEL_STACK
          if (rtcb->xcp.ustkptr != NULL)
            {
              ret = backtrace(rtcb->stack_base_ptr, (uintptr_t *)
                              ((uintptr_t)rtcb->stack_base_ptr +
                               rtcb->adj_stack_size),
                              (void *)*(rtcb->xcp.ustkptr + 1), NULL,
                              buffer, size, &skip);
            }
          else
#endif
            {
              ret = backtrace(rtcb->stack_base_ptr, (uintptr_t *)
                              ((uintptr_t)rtcb->stack_base_ptr +
                               rtcb->adj_stack_size),
                              (void *)getfp(), NULL, buffer, size, &skip);
            }
        }
    }
  else
    {
#ifdef CONFIG_ARCH_KERNEL_STACK
      if (tcb->xcp.ustkptr != NULL)
        {
          ret = backtrace(tcb->stack_base_ptr,
                          (uintptr_t *)((uintptr_t)tcb->stack_base_ptr +
                                        tcb->adj_stack_size),
                          (void *)*(tcb->xcp.ustkptr + 1), NULL,
                          buffer, size, &skip);
        }
      else
#endif
        {
          ret = backtrace(tcb->stack_base_ptr,
                          (uintptr_t *)((uintptr_t)tcb->stack_base_ptr +
                                        tcb->adj_stack_size),
                          (void *)tcb->xcp.regs[REG_FP],
                          (void *)tcb->xcp.regs[REG_EPC],
                          buffer, size, &skip);
        }
    }

  return ret;
}
