/****************************************************************************
 * libs/libc/netdb/lib_proto.c
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

#include <netdb.h>
#include <string.h>

/****************************************************************************
 * Private Data
 ****************************************************************************/

static struct protoent result_buf;

/****************************************************************************
 * Public Functions
 ****************************************************************************/

void endprotoent(void)
{
  endprotoent_r(&result_buf);
}

void setprotoent(int stayopen)
{
  setprotoent_r(stayopen, &result_buf);
}

FAR struct protoent *getprotoent(void)
{
  FAR struct protoent *result;
  int ret = getprotoent_r(&result_buf, NULL, 0, &result);
  return ret == OK ? &result_buf : NULL;
}

FAR struct protoent *getprotobyname(FAR const char *name)
{
  FAR struct protoent *result;
  int ret = getprotobyname_r(name, &result_buf, NULL, 0, &result);
  return ret == OK ? &result_buf : NULL;
}

FAR struct protoent *getprotobynumber(int proto)
{
  FAR struct protoent *result;
  int ret = getprotobynumber_r(proto, &result_buf, NULL, 0, &result);
  return ret == OK ? &result_buf : NULL;
}
