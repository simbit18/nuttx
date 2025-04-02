#!/usr/bin/env pswd
############################################################################
# tools/sethost.ps1
# PowerShell script for CI on Windows Native
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.  The
# ASF licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.
#
############################################################################

# Set-PSDebug -Trace 0

Write-Host "Run sethost.ps1 !!!" -ForegroundColor Yellow
$progname = $($MyInvocation.MyCommand.Name)

$MAKECMD = "make"
$host_os = $null
$wenv = $null
$cpu = $null

function showusage {
  Write-Host ""
  Write-Host "USAGE: $progname [-l|m|c|g|n|B] [make-opts]"
  Write-Host "       $progname -h"
  Write-Host ""
  Write-Host "Where:"
  Write-Host "  -l|m|c|g|n|B selects Linux (l), macOS (m), Cygwin (c), BSD (B),"
  Write-Host "     MSYS/MSYS2 (g) or Windows native (n). Default Linux"
  Write-Host "  make-opts directly pass to make"
  Write-Host "  -h will show this help test and terminate."
  exit 1
}

# Parse command line


<# while [ ! -z "$1" ]; do
  case $1 in
  -l )
    host=linux
    ;;
  -c )
    host=windows
    wenv=cygwin
    ;;
  -g )
    host=windows
    wenv=msys
    ;;
  -m )
    host=macos
    ;;
  -n )
    host=windows
    wenv=native
    ;;
  -B )
    host=bsd
    MAKECMD="gmake"
    ;;
  -h )
    showusage
    ;;
  * )
    break
    ;;
  esac
  shift
done #>

write-host "There are a total of $($args.count) arguments"

if (!$args[0]) {
  showusage
}
for ( $i = 0; $i -lt $args.count; $i++ ) {
  write-host "Argument  $i is $($args[$i])"
  # switch ($($args[$i].replace(" ",''))) {
  switch -regex -casesensitive ($($args[$i])) {
    '-h' {
      # Write-Host "-h" -ForegroundColor Green
      showusage
    }
    '-l' {
      # Write-Host "-l" -ForegroundColor Green
      $host_os = "linux"
    }
    '-c' {
      # Write-Host "-c" -ForegroundColor Green
      $host_os = "windows"
      $wenv = "cygwin"
    }
    '-g' {
      # Write-Host "-g" -ForegroundColor Green
      $host_os = "windows"
      $wenv = "msys"
    }
    '-m' {
      # Write-Host "-m" -ForegroundColor Green
      $host_os = "macos"
    }
    '-n' {
      # Write-Host "-n" -ForegroundColor Green
      $host_os = "windows"
      $wenv = "native"
    }
    '-B' {
      # Write-Host "-B" -ForegroundColor Green
      $host_os = "bsd"
      $MAKECMD = "gmake"
    }
    default {
      Write-Host "boardconfig $($args[$i])" -ForegroundColor Green
      #$boardconfig = $($args[$i])
    }
  }
}

# If the host was not explicitly given, try to guess.

if ($null -eq $host_os) {
  Write-Host "Missing host_os argument"
  $host_os = "windows"
  $wenv = "native"
}

# Detect Host CPU type.
# At least MacOS and Linux can have x86_64 and arm based hosts.

if ($null -eq $cpu) {
  Write-Host "Missing cpu argument"
  $cpu = "x86_64"
}

$WD = Get-Location
Write-Host "The WD path $WD" -ForegroundColor Green

if (Test-Path -Path "sethost.ps1") {
  # Try direct path used with custom configurations.
  Write-Host "Directory for sethost.ps1 exist." -ForegroundColor Yellow
  $WD = Resolve-Path("Get-Location\..\..")
  Write-Host "$WD= $WD" -ForegroundColor Yellow
  Set-Location $WD
}

if (Test-Path -Path "$WD\tools\sethost.ps1") {
  # Try direct path used with custom configurations.
  Write-Host "Directory for sethost.ps1 $WD exist." -ForegroundColor Yellow
  $nuttx = $WD
}
else {
  Write-Host "This script must be executed in nuttx/ or nuttx/tools directories" -ForegroundColor Yellow
  exit 1

}

if (-Not (Test-Path -Path "$nuttx\.config")) {
  Write-Host "There is no .config at $nuttx" -ForegroundColor Yellow
  exit 1
}

$dest_config = "$nuttx\.config"

if (-Not (Test-Path -Path "$nuttx\Make.defs")) {
  Write-Host "ERROR: No readable Make.defs file exists at $nuttx" -ForegroundColor Yellow
  exit 1
}

# Modify the configuration

if (("linux" -eq $host_os) -or ("macos" -eq $host_os) -or ("bsd" -eq $host_os)) {
  # Disable Windows (to suppress warnings from Window Environment selections)
  & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_WINDOWS"

  # Enable Linux or macOS or BSD

  switch -regex -casesensitive ($host_os) {
    'linux' {
      Write-Host "  Select Linux host"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_BSD"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_MACOS"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_OTHER"
      & kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_HOST_LINUX"
      if ("arm64" -eq $cpu) {
        & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_ARM64"
      }
      Break
    }
    'bsd' {
      Write-Host "  Select BSD host"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_LINUX"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_MACOS"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_OTHER"
      & kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_HOST_BSD"
      Break
    }
    'macos' {
      Write-Host "  Select macOS host"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_BSD"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_LINUX"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_OTHER"
      & kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_HOST_MACOS"
      if ("arm64" -eq $cpu) {
        & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_ARM64"
      }
      Break
    }
    default {
      Write-Host "Default $host_os"
    }
  }
  # Enable the System V ABI
  & kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_SIM_X8664_SYSTEMV"
}
else {
  & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_BSD"
  & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_LINUX"
  & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_MACOS"
  & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_OTHER"

  # Enable Windows and the Microsoft ABI
  & kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_HOST_WINDOWS"
  & kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_SIM_X8664_MICROSOFT"
  & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_SIM_X8664_SYSTEMV"

  # Enable Windows environment
  switch -regex -casesensitive ($wenv) {
    'cygwin' {
      Write-Host "  Select Windows Cygwin host."
      & kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_WINDOWS_CYGWIN"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_MSYS"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_EXPERIMENTAL"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_NATIVE"
      Break
    }
    'msys' {
      Write-Host "  Select Windows MSYS host."
      & kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_WINDOWS_MSYS"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_CYGWIN"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_EXPERIMENTAL"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_NATIVE"
      Break
    }
    'native' {
      Write-Host "  Select Windows native host."
      
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_CYGWIN"
      & kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_MSYS"
      & kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_EXPERIMENTAL"
      & kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_WINDOWS_NATIVE"
      Break
    }
    default {
      Write-Host "Default $wenv"
    }
  }
}

Write-Host "  Refreshing..."

try {
  Write-Host "make olddefconfig -j"
  & cmd.exe /C `"make olddefconfig -j `"
}
catch {
  Write-Host "ERROR: failed to refresh" -ForegroundColor Red
}
