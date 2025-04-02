#!/usr/bin/env pswd
############################################################################
# tools/configure.ps1
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

$myname = $($MyInvocation.MyCommand.Name)

Write-Host "Run configure.ps1 !!!" -ForegroundColor Yellow

$WD = Get-Location
Write-Host "The WD path $WD" -ForegroundColor Green
$TOPDIR = Resolve-Path("Get-Location\..")
Write-Host "The TOPDIR path $TOPDIR" -ForegroundColor Green
$WSDIR = "$TOPDIR\.."
Write-Host "The WSDIR path $WSDIR" -ForegroundColor Green
$MAKECMD = "make"
Write-Host "MAKECMD = $MAKECMD" -ForegroundColor Green

function showusage {
  Write-Host ""
  Write-Host "Usage: $myname [-E] [-e] [-S] [-l|m|c|g|n|B] [-L [boardname]] [-a <app-dir>] <board-selection> [make-opts]" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "Where:"
  Write-Host "  -E enforces distclean if already configured."
  Write-Host "  -e performs distclean if configuration changed."
  Write-Host "  -S adds the nxtmpdir folder for third-party packages."
  Write-Host "  -l selects the Linux (l) host environment."
  Write-Host "  -m selects the macOS (m) host environment."
  Write-Host "  -c selects the Windows host and Cygwin (c) environment."
  Write-Host "  -g selects the Windows host and MinGW/MSYS environment."
  Write-Host "  -n selects the Windows host and Windows native (n) environment."
  Write-Host "  -B selects the *BSD (B) host environment."
  Write-Host "  Default: Use host setup in the defconfig file"
  Write-Host "  Default Windows: Cygwin"
  Write-Host "  -L lists available configurations for given boards, or all boards if no"
  Write-Host "     board is given. board name can be partial here."
  Write-Host "  -a <app-dir> is the path to the apps/ directory, relative to the nuttx"
  Write-Host "     directory"
  Write-Host "  <board-selection> is either:"
  Write-Host "    For in-tree boards: a <board-name>:<config-name> pair where <board-name> is"
  Write-Host "    the name of the board in the boards directory and <config-name> is the name"
  Write-Host "    of the board configuration sub-directory (e.g. boardname:nsh), or: For"
  Write-Host "    out-of-tree custom boards: a path to the board's configuration directory,"
  Write-Host "    either relative to TOPDIR (e.g. ../mycustomboards/myboardname/config/nsh)"
  Write-Host "    or an absolute path."
  Write-Host " make-opts directly pass to make"
  Write-Host "$myname doesn't check the validity of the .config file. This is done at next"
  Write-Host "make time."
  Write-Host ""

}

$OPTFILES = @(
  ".gdbinit",
  ".cproject",
  ".project"
)

# Parse command arguments

$boardconfig = $null
$winnative = $null
$appdir = $null
$host_os = $null
$enforce_distclean = $null
$distclean = $null
$store_nxtmpdir = $null

function dumpcfgs {
  param (
    [string]$boards_name
  )
  Write-Host "Searching for the path boards: $TOPDIR\boards\* " -ForegroundColor Green
  $filePath = @()
  if ($boards_name -eq $null) {
    # Searching for the file
    Write-Host "Searching for the all boards: " -ForegroundColor Green
    $filePath = Get-ChildItem -Path "$TOPDIR\boards\*" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "defconfig" }
  }
  else {
    Write-Host "Searching for the path boards: $boards_name" -ForegroundColor Green
    $filePath = Get-ChildItem -Path "$TOPDIR\boards\*" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "defconfig" -and $_.DirectoryName -match "$boards_name" }
  }
  foreach ($i in $filePath) {
    $arrpath = $($i.FullName) -split '\\'
    $board_config = "$($arrpath[$arrpath.count - 4]):$($arrpath[$arrpath.count - 2])"
    Write-Host "$board_config"
  }
  Write-Host "There are a total of $($filePath.count) occurrence."
}

function Search-Folder() {
  param (
    [string]$boards_name
  )
  $fileboards = "$TOPDIR\boards\*"
  #$SearchTerm = "run"
  $regex = 'defconfig'
  if ($boards_name -eq $null) {
    # Searching for the file
    Write-Host "Searching for the path boards: " -ForegroundColor Green
    $children = Get-ChildItem -Path $fileboards -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "$regex" }
  }
  else {
    $children = Get-ChildItem -Path $fileboards -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "$regex" -and $_.DirectoryName -match "$boards_name" }
  }
  # Get children
  # For each child, see if it matches the search term, and if it is a folder, search it too.
  foreach ($child in $children) {
    $arrpath = $($child.FullName) -split '\\'
    $list = "$($arrpath[$arrpath.count - 4]):$($arrpath[$arrpath.count - 2])"
    Write-Host "$list"
  }
  Write-Host "There are a total of $($children.count) occurrence."
}

write-host "There are a total of $($args.count) arguments"
if (!$args[0]) {
  showusage
}
for ( $i = 0; $i -lt $args.count; $i++ ) {
  write-host "Argument  $i is $($args[$i])"
  switch -regex -casesensitive ($($args[$i])) {
    '-h' {
      showusage
      return 0
    }
    '-a' {
      # Write-Host "-a" -ForegroundColor Green
      $appdir = $($args[$i + 1])
      $i += 1
      continue
    }
    ' -c | -g | -l | -m ' {
      Write-Host " -c | -g | -l | -m " -ForegroundColor Green
      $winnative = 'n'
      $host_os += " $($args[$i])"
    }
    '-n' {
      Write-Host "-n" -ForegroundColor Green
      $winnative = 'y'
      $host_os += " $($args[$i])"
      #continue
    }
    '-B' {
      # Write-Host "-B" -ForegroundColor Green
      $winnative = 'n'
      $host_os += " $($args[$i])"
      $MAKECMD = "gmake"
      #continue
    }
    '-E' {
      # Write-Host "-N" -ForegroundColor Green
      $enforce_distclean = 'y'
      #continue
    }
    '-e' {
      # Write-Host "-N" -ForegroundColor Green
      $distclean = 'y'
      #continue
    }
    '-L' {
      Write-Host "-L" -ForegroundColor Green
      if (!$args[$i + 1]) {
        # Write-Host "-L0" -ForegroundColor Green
        dumpcfgs # Search-Folder
      }
      else {
        # Write-Host "-L1" -ForegroundColor Green
        dumpcfgs $($args[$i + 1])
        # Search-Folder $($args[$i + 1])
      }
      # $i += 1
      return 0
    }
    '-S' {
      # Write-Host "-N" -ForegroundColor Green
      $store_nxtmpdir = 'y'
      #continue
    }
    default {
      Write-Host "boardconfig $($args[$i])" -ForegroundColor Green
      $boardconfig = $($args[$i])
    }
  }
}

# Sanity checking

if ($null -eq $boardconfig) {
  Write-Host "Missing <board/config> argument"
  showusage
  exit 2
}

$boardconfig = $boardconfig -replace '/', ':'
Write-Host "boardconfig: $boardconfig" -ForegroundColor Green
$tmparr = $boardconfig -split ':'
$boarddir = $($tmparr[0])
Write-Host "boarddir: $boarddir"

$configdir = $($tmparr[1])
Write-Host "configdir: $configdir"

$configpath = "$TOPDIR\boards\*\*\$boarddir\configs\$configdir"

Write-Host "configpath: $configpath"

if (-Not (Test-Path -Path $configpath)) {
  # Try direct path used with custom configurations.
  $configpath = "$TOPDIR\$boardconfig"
  if (-Not (Test-Path -Path $configpath)) {
    Write-Host "Directory for $boardconfig does not exist." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run tools\configure.ps1 -L to list available configurations." -ForegroundColor Yellow
    showusage
    exit 3
  }
}

$src_makedefs = "$TOPDIR\boards\*\*\$boarddir\configs\$configdir\Make.defs"
$dest_makedefs = "$TOPDIR\Make.defs"

if (-Not (Test-Path -Path $src_makedefs)) {
  # Try direct path used with custom configurations.
  $src_makedefs = "$TOPDIR\boards\*\*\$boarddir\scripts\Make.defs"
  if (-Not (Test-Path -Path $src_makedefs)) {
    $src_makedefs = "$configpath\Make.defs"
    if (-Not (Test-Path -Path $src_makedefs)) {
      $src_makedefs = "$configpath\..\..\scripts\Make.defs"
      if (-Not (Test-Path -Path $src_makedefs)) {
        $src_makedefs = "$configpath\..\..\..\common\scripts\Make.defs"
        if (-Not (Test-Path -Path $src_makedefs)) {
          Write-Host "File Make.defs could not be found" -ForegroundColor Yellow
          exit 4
        }
      }
    }
  }
}

$src_config = "$configpath\defconfig"
$dest_config = "$TOPDIR\.config"
$original_config = "$TOPDIR\.config.orig"
$backup_config = "$TOPDIR\defconfig"

if (-Not (Test-Path -Path $src_config)) {
  Write-Host "File $src_config does not exist." -ForegroundColor Yellow
  exit 5
}

if (Test-Path -Path $dest_config) {
  if ($enforce_distclean -eq "y") {
    & cmd.exe /C `"make -C $TOPDIR distclean 2`>`&1 `"
  }
  else {
    # test
    if ((Get-FileHash "$src_config").Hash -eq (Get-FileHash "$backup_config").Hash) {
      Write-Host "No configuration change." -ForegroundColor Yellow
      exit 0
    }
    if ($distclean -eq "y") {
      & cmd.exe /C `"make -C $TOPDIR distclean 2`>`&1 `"
    }
    else {
      Write-Host "Already configured!" -ForegroundColor Yellow
      Write-Host "Please 'make distclean' and try again." -ForegroundColor Yellow
      exit 6
    }
  }
}

if ($store_nxtmpdir -eq "y") {
  New-Item -ItemType Directory -Path "$WSDIR\nxtmpdir" -Force > $null
  Write-Host "Folder $WSDIR\nxtmpdir created." -ForegroundColor Green
}
else {
  Remove-Item "$WSDIR\nxtmpdir*" -Force
  Write-Host "Folder $WSDIR\nxtmpdir clean." -ForegroundColor Green
}

# Okay... Everything looks good.  Setup the configuration

Write-Host "  Copy files" -ForegroundColor Green
try {
  Copy-Item -Path "$src_makedefs" -Destination "$dest_makedefs"
}
catch {
  Write-Host "Failed to copy file $src_makedefs : $_" -ForegroundColor Red
}
try {
  Copy-Item -Path "$src_config" -Destination "$dest_config"
  Copy-Item -Path "$src_config" -Destination "$backup_config"
}
catch {
  Write-Host "Failed to backup $src_config : $_" -ForegroundColor Red
}


# Install any optional files

<# for opt in ${OPTFILES}; do
  test -f ${configpath}/${opt} && install ${configpath}/${opt} "${TOPDIR}/"
done #>
foreach ( $opt in $OPTFILES ) {
  if (Test-Path -Path "$configpath\$opt") {
    Copy-Item -Path "$configpath\$opt" -Destination "$TOPDIR"
  }
}


# Extract values needed from the defconfig file.  We need:
# (1) The CONFIG_WINDOWS_NATIVE setting to know it this is target for a
#     native Windows
# (2) The CONFIG_APPS_DIR setting to see if there is a configured location for the
#     application directory.  This can be overridden from the command line.

# If we are going to some host other than windows native or to a windows
# native host, then don't even check what is in the defconfig file.

Write-Host "defconfig check " -ForegroundColor Green
# prendiamo tutte le corrispondenze
$patternallitem = "CONFIG_WINDOWS_NATIVE="
$contentdefconfig = Get-Content "$src_config"
#$listtoolchain = Select-String -Path "$nuttx\build\.config" -Pattern $patternallitem
$listdefconfig = $contentdefconfig | Select-String $patternallitem -AllMatches
Write-Host "listdefconfig: $listdefconfig" -ForegroundColor Green

$defconfigarr = $listdefconfig -split '='
Write-Host "defconfigarr: $defconfigarr"
$oldnative = $($defconfigarr[1])
Write-Host "oldnative: $oldnative"
if ($null -eq $oldnative) {
  $oldnative = "n"
}
if ($null -eq $winnative) {
  $winnative = $oldnative
}
Write-Host "winnative: $winnative"
  
  
# If no application directory was provided on the command line and we are
# switching between a windows native host and some other host then ignore the
# path to the apps/ directory in the defconfig file.  It will most certainly
# not be in a usable form.

$defappdir = "y"
if (($null -eq $appdir) -and ($oldnative -eq $winnative)) {
  $listdefconfig = $null
  $patternallitem = "^CONFIG_APPS_DIR="
  $listdefconfig = $contentdefconfig | Select-String $patternallitem -AllMatches
  $quotedgarr = $listdefconfig -split '='
  Write-Host "quotedgarr: $quotedgarr"
  $quoted = $($quotedgarr[1])
  if ($quoted) {
    $appdir = $quoted -replace '"', ''
    Write-Host "appdir: $appdir"
    $defappdir = "n"
  }
}
# Check for the apps/ directory in the usual place if appdir was not provided

<# if [ -z "${appdir}" ]; then

  # Check for a version file

  unset CONFIG_VERSION_STRING
  if [ -x "${TOPDIR}/.version" ]; then
    . "${TOPDIR}/.version"
  fi
#>

# Check for the apps/ directory in the usual place if appdir was not provided
if ($null -eq $appdir) {
    
  # Check for a version file
  # to-do

  # Check for an unversioned apps/ directory

  if (Test-Path -Path "$TOPDIR\..\apps") {
    $appdir = "..`\\apps"
    Write-Host "appdir: $appdir" -ForegroundColor Yellow
  }
  elseif (Test-Path -Path "$TOPDIR\..\nuttx-apps") {
    $appdir = "..`\\nuttx-apps"
    Write-Host "appdir: $findval_val" -ForegroundColor Yellow
  }
  elseif (Test-Path -Path "$TOPDIR\..\nuttx-apps.git") {
    $appdir = "..`\\nuttx-apps.git"
    Write-Host "appdir: $appdir" -ForegroundColor Yellow
  }
  else {
    # Check for a versioned apps/ directory
    if (Test-Path -Path "$TOPDIR\..\apps-$CONFIG_VERSION_STRING") {
      $appdir = "..`\\apps-$CONFIG_VERSION_STRING"
      Write-Host "appdir: $appdir" -ForegroundColor Yellow
    }
    else {  
      Write-Host "ERROR: Could not find the path to the appdir" -ForegroundColor Yellow
      exit 7
    }
  }
}
# For checking the apps dir path, we need a POSIX version of the relative path.

<# posappdir=`echo "${appdir}" | sed -e 's/\\\\/\\//g'`
winappdir=`echo "${appdir}" | sed -e 's/\\//\\\\\\\/g'` #>


$posappdir = $appdir -replace '\\', '/'
$winappdir = $appdir -replace '/', '\\'

# If appsdir was provided (or discovered) then make sure that the apps/
# directory exists

<# if [ ! -z "${appdir}" -a ! -d "${TOPDIR}/${posappdir}" ]; then
  echo "Directory \"${TOPDIR}/${posappdir}\" does not exist"
  exit 7
fi #>
# Is windows
if (($appdir) -and (-Not (Test-Path -Path "$TOPDIR\$winappdir"))) {
  Write-Host "Directory $TOPDIR\$winappdir does not exist" -ForegroundColor Red
  exit 7
}
# If we did not use the CONFIG_APPS_DIR that was in the defconfig config file,
# then append the correct application information to the tail of the .config
# file

if ($defappdir -eq "y") {
  Add-Content -NoNewLine -Path $dest_config -Value "`n# Application configuration`n`n"
  
  if ($winnative -eq "y") {
    # $tmpapps = "CONFIG_APPS_DIR=\`"$winappdir\`"`n"
    Add-Content -NoNewLine -Path "$dest_config" -Value "CONFIG_APPS_DIR=`"$winappdir`"`n"
  }
  else {
    # $tmpapps = "CONFIG_APPS_DIR=\`"$posappdir\`"`n"
    Add-Content -NoNewLine -Path "$dest_config" -Value "CONFIG_APPS_DIR=`"$posappdir`"`n"
  }
}
# Update the CONFIG_BASE_DEFCONFIG setting

<# posboardconfig=`echo "${boardconfig}" | sed -e 's/\\\\/\\//g'`
echo "CONFIG_BASE_DEFCONFIG=\"$posboardconfig\"" >> "${dest_config}" #>
#$posboardconfig = "CONFIG_BASE_DEFCONFIG=\`"$posboardconfig\`"`n"
Add-Content -NoNewLine -Path $dest_config -Value "CONFIG_BASE_DEFCONFIG=`"$boarddir`"`n"


# The saved defconfig files are all in compressed format and must be
# reconstitued before they can be used.

& "$TOPDIR\tools\sethost.ps1" "$host_os"

# Save the original configuration file without CONFIG_BASE_DEFCONFIG
# for later comparison
  
# Get-Content "$dest_config" | Select-String -Pattern "CONFIG_BASE_DEFCONFIG*" -NotMatch | % { $_.Line } | Out-File $original_config
# alternative
Get-Content "$dest_config" | Select-String -Pattern "CONFIG_BASE_DEFCONFIG*" -NotMatch | ForEach-Object { $_.Line } | Out-File $original_config
