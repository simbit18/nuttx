/****************************************************************************
 * libs/libc/stdio/lib_fgetc.c
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

#include <stdio.h>
#include "libc.h"

/****************************************************************************
 * Public Functions
 ****************************************************************************/

/****************************************************************************
 * fgetc
 ****************************************************************************/

int fgetc_unlocked(FAR FILE *stream)
{
  unsigned char ch;
  ssize_t ret;

  ret = lib_fread_unlocked(&ch, 1, stream);
  if (ret > 0)
    {
      return ch;
    }
  else
    {
      return EOF;
    }
}

int fgetc(FAR FILE *stream)
{
  int ret;

  flockfile(stream);
  ret = fgetc_unlocked(stream);
  funlockfile(stream);

  return ret;
}
