#!/usr/bin/env pswd
# tools/configure.ps1
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

# set -e
Set-PSDebug -Trace 0
Write-Host "Run configure.ps1 !!!" -ForegroundColor Yellow

<# WD=`test -d ${0%/*} && cd ${0%/*}; pwd`
TOPDIR="${WD}/.."
WSDIR=`cd "${TOPDIR}/.." && pwd -P`
MAKECMD="make"
 #>

$WD = Get-Location
Write-Host "The WD path $WD" -ForegroundColor Green
$TOPDIR=Resolve-Path("Get-Location\..")
Write-Host "The TOPDIR path $TOPDIR" -ForegroundColor Green
$WSDIR="$TOPDIR\.."
Write-Host "The WSDIR path $WSDIR" -ForegroundColor Green
$MAKECMD="make"
Write-Host "MAKECMD = $MAKECMD" -ForegroundColor Green

<# USAGE="
USAGE: ${0} [-E] [-e] [-S] [-l|m|c|g|n|B] [-L [boardname]] [-a <app-dir>] <board-selection> [make-opts]

Where:
  -E enforces distclean if already configured.
  -e performs distclean if configuration changed.
  -S adds the nxtmpdir folder for third-party packages.
  -l selects the Linux (l) host environment.
  -m selects the macOS (m) host environment.
  -c selects the Windows host and Cygwin (c) environment.
  -g selects the Windows host and MinGW/MSYS environment.
  -n selects the Windows host and Windows native (n) environment.
  -B selects the *BSD (B) host environment.
  Default: Use host setup in the defconfig file
  Default Windows: Cygwin
  -L lists available configurations for given boards, or all boards if no
     board is given. board name can be partial here.
  -a <app-dir> is the path to the apps/ directory, relative to the nuttx
     directory
  <board-selection> is either:
    For in-tree boards: a <board-name>:<config-name> pair where <board-name> is
    the name of the board in the boards directory and <config-name> is the name
    of the board configuration sub-directory (e.g. boardname:nsh), or: For
    out-of-tree custom boards: a path to the board's configuration directory,
    either relative to TOPDIR (e.g. ../mycustomboards/myboardname/config/nsh)
    or an absolute path.
  make-opts directly pass to make

" #>
$myname=$($MyInvocation.MyCommand.Name)

function showusage {
  Write-Host ""
  Write-Host "Usage: $myname [-E] [-e] [-S] [-l|m|c|g|n|B] [-L [boardname]] [-a <app-dir>] <board-selection> [make-opts]" -ForegroundColor Cyan
  Write-Host "" -ForegroundColor Yellow
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



# A list of optional files that may be installed

<# OPTFILES="\
  .gdbinit\
  .cproject\
  .project\
" #>

$OPTFILES = @(
  ".gdbinit",
  ".cproject",
  ".project"
)


# Parse command arguments

<# unset boardconfig
unset winnative
unset appdir
unset host
unset enforce_distclean
unset distclean
unset store_nxtmpdir #>

$boardconfig = $null
$winnative = $null
$appdir = $null
$host_os = $null
$enforce_distclean = $null
$distclean = $null
$store_nxtmpdir = $null


function dumpcfgs {
<#   if [ -n "$1" ]; then
    local boards=$(find ${TOPDIR}/boards -mindepth 3 -maxdepth 3 -type d -name "*$1*")
    [ -z "$boards" ] && { echo board "$1" not found; return ;}
    configlist=$(find $boards -name defconfig -type f)
  else
    configlist=$(find ${TOPDIR}/boards -name defconfig -type f)
  fi
  for defconfig in ${configlist}; do
    config=`dirname ${defconfig} | sed -e "s,${TOPDIR}/boards/,,g"`
    boardname=`echo ${config} | cut -d'/' -f3`
    configname=`echo ${config} | cut -d'/' -f5`
    echo "  ${boardname}:${configname}"
  done #>
}

<# while [ ! -z "$1" ]; do
  case "$1" in
  -a )
    shift
    appdir=$1
    ;;
  -c | -g | -l | -m )
    winnative=n
    host+=" $1"
    ;;
  -n )
    winnative=y
    host+=" $1"
    ;;
  -B )
    winnative=n
    host+=" $1"
    MAKECMD="gmake"
    ;;
  -E )
    enforce_distclean=y
    ;;
  -e )
    distclean=y
    ;;
  -h )
    echo "$USAGE"
    exit 0
    ;;
  -L )
    shift
    dumpcfgs $1
    exit 0
    ;;
  -S )
    store_nxtmpdir=y
    ;;
  *)
    boardconfig=$1
    shift
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
            return 0
        }
        '-a' {
            # Write-Host "-a" -ForegroundColor Green
            $appdir = $($args[$i+1])
            $i += 1
            continue
        }
        ' -c | -g | -l | -m ' {
            # Write-Host "-c|-g|-l|-m" -ForegroundColor Green
            $winnative = 'n'
            $host_os += " $($args[$i])"
            continue
        }
        '-n' {
            # Write-Host "-n" -ForegroundColor Green
            $winnative = 'y'
            $host_os += " $($args[$i])"
            continue
        }
        '-B' {
            # Write-Host "-B" -ForegroundColor Green
            $winnative = 'n'
            $host_os += " $($args[$i])"
            $MAKECMD = "gmake"
            continue
        }
        '-E' {
            # Write-Host "-N" -ForegroundColor Green
            $enforce_distclean = 'y'
            continue
        }
        '-e' {
            # Write-Host "-N" -ForegroundColor Green
            $distclean = 'y'
            continue
        }
        '-L' {
            # Write-Host "-N" -ForegroundColor Green
            dumpcfgs $($args[$i+1])
            $i += 1
            return 0
        }
        '-S' {
            # Write-Host "-N" -ForegroundColor Green
            $store_nxtmpdir = 'y'
            continue
        }
        default {
            Write-Host "boardconfig $($args[$i])" -ForegroundColor Green
            $boardconfig=$($args[$i])
        }
    }
}

# Sanity checking

<# if [ -z "${boardconfig}" ]; then
  echo "" 1>&2
  echo "Missing <board/config> argument" 1>&2
  echo "$USAGE" 1>&2
  exit 2
fi #>

if ($boardconfig -eq $null) {
    Write-Host "Missing <board/config> argument"
    showusage
    exit 2
  }



<# configdir=`echo ${boardconfig} | cut -s -d':' -f2`
if [ -z "${configdir}" ]; then
  boarddir=`echo ${boardconfig} | cut -d'/' -f1`
  configdir=`echo ${boardconfig} | cut -d'/' -f2`
else
  boarddir=`echo ${boardconfig} | cut -d':' -f1`
fi

configpath=${TOPDIR}/boards/*/*/${boarddir}/configs/${configdir}
if [ ! -d ${configpath} ]; then
  # Try direct path used with custom configurations.

  configpath=${TOPDIR}/${boardconfig}
  if [ ! -d ${configpath} ]; then
    configpath=${boardconfig}
    if [ ! -d ${configpath} ]; then
      echo "Directory for ${boardconfig} does not exist." 1>&2
      echo "" 1>&2
      echo "Run tools/configure.sh -L to list available configurations." 1>&2
      echo "$USAGE" 1>&2
      exit 3
    fi
  fi
fi #>
$boardconfig = $boardconfig -replace '/', ':'
Write-Host "boardconfig: $boardconfig" -ForegroundColor Green
$tmparr = $boardconfig -split ':'
$boarddir = $($tmparr[0])
Write-Host "boarddir: $boarddir"

$configdir=$($tmparr[1])
Write-Host "configdir: $configdir"

$configpath="$TOPDIR\boards\*\*\$boarddir\configs\$configdir"

Write-Host "configpath: $configpath"

if (-Not (Test-Path -Path $configpath)) {
    # Try direct path used with custom configurations.
    $configpath="$TOPDIR\$boardconfig"
    if (-Not (Test-Path -Path $configpath)) {
        Write-Host "Directory for $boardconfig does not exist." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Run tools/configure.sh -L to list available configurations." -ForegroundColor Yellow
        showusage
        exit 3
  }
}

<# src_makedefs=${TOPDIR}/boards/*/*/${boarddir}/configs/${configdir}/Make.defs
dest_makedefs="${TOPDIR}/Make.defs" #>

$src_makedefs="$TOPDIR\boards\*\*\$boarddir\configs\$configdir\Make.defs"
$dest_makedefs="$TOPDIR\Make.defs"

<# if [ ! -r ${src_makedefs} ]; then
  src_makedefs=${TOPDIR}/boards/*/*/${boarddir}/scripts/Make.defs

  if [ ! -r ${src_makedefs} ]; then
    src_makedefs=${configpath}/Make.defs
    if [ ! -r ${src_makedefs} ]; then
      src_makedefs=${configpath}/../../scripts/Make.defs

      if [ ! -r ${src_makedefs} ]; then
        src_makedefs=${configpath}/../../../common/scripts/Make.defs

        if [ ! -r ${src_makedefs} ]; then
          echo "File Make.defs could not be found"
          exit 4
        fi
      fi
    fi
  fi
fi #>

if (-Not (Test-Path -Path $src_makedefs)) {
    # Try direct path used with custom configurations.
    $src_makedefs = "$TOPDIR\boards\*\*\$boarddir\scripts\Make.defs"
    if (-Not (Test-Path -Path $src_makedefs)) {
        $src_makedefs = "$configpath\Make.defs"
        if (-Not (Test-Path -Path $src_makedefs)) {
            $src_makedefs = "$configpath\*\*\scripts\Make.defs"
            if (-Not (Test-Path -Path $src_makedefs)) {
                $src_makedefs = "$configpath\*\*\*\common\scripts\Make.defs"
                if (-Not (Test-Path -Path $src_makedefs)) {
                    Write-Host "File Make.defs could not be found" -ForegroundColor Yellow
                    exit 4
                }
            }
        }
    }
}

<# src_config=${configpath}/defconfig
dest_config="${TOPDIR}/.config"
original_config="${TOPDIR}/.config.orig"
backup_config="${TOPDIR}/defconfig" #>

$src_config = "$configpath\defconfig"
$dest_config = "$TOPDIR\.config"
$original_config = "$TOPDIR\.config.orig"
$backup_config = "$TOPDIR\defconfig"

<# if [ ! -r ${src_config} ]; then
  echo "File ${src_config} does not exist"
  exit 5
fi #>


if (-Not (Test-Path -Path $src_config)) {
    Write-Host "File $src_config does not exist." -ForegroundColor Yellow
    exit 5
}


<# if [ -r ${dest_config} ]; then
  if [ "X${enforce_distclean}" = "Xy" ]; then
    ${MAKECMD} -C ${TOPDIR} distclean
  else
    if cmp -s ${src_config} ${backup_config}; then
      echo "No configuration change."
      exit 0
    fi

    if [ "X${distclean}" = "Xy" ]; then
      ${MAKECMD} -C ${TOPDIR} distclean
    else
      echo "Already configured!"
      echo "Please 'make distclean' and try again."
      exit 6
    fi
  fi
fi#>

if (Test-Path -Path $dest_config) {
    if ($enforce_distclean -eq "y") {
        & cmd.exe /C `"make distclean 2`>`&1 `"
    } else {
# test
        if ((Get-FileHash "$src_config").Hash -eq (Get-FileHash "$backup_config").Hash) {
            Write-Host "No configuration change." -ForegroundColor Yellow
            exit 0
        }
        if ($distclean -eq "y") {
            & cmd.exe /C `"make distclean 2`>`&1 `"
        } else {
            Write-Host "Already configured!" -ForegroundColor Yellow
            Write-Host "Please 'make distclean' and try again." -ForegroundColor Yellow
            exit 6
        }
    }
}


<# if [ "X${store_nxtmpdir}" = "Xy" ]; then
  if [ ! -d "${WSDIR}/nxtmpdir" ]; then
    mkdir -p "${WSDIR}/nxtmpdir"
    echo "Folder ${WSDIR}/nxtmpdir created."
  fi
else
  if [ -d "${WSDIR}/nxtmpdir" ]; then
    rm -rf "${WSDIR}/nxtmpdir"
    echo "Folder ${WSDIR}/nxtmpdir clean."
  fi
fi #>



if ($store_nxtmpdir -eq "y") {
    New-Item -ItemType Directory -Path "$WSDIR\nxtmpdir" -Force > $null
    Write-Host "Folder $WSDIR\nxtmpdir created." -ForegroundColor Green
} else {
    Remove-Item "$WSDIR\nxtmpdir*" -Force
    Write-Host "Folder $WSDIR\nxtmpdir clean." -ForegroundColor Green
}

# Okay... Everything looks good.  Setup the configuration

<# echo "  Copy files"
ln -sf ${src_makedefs} ${dest_makedefs} || \
  { echo "Failed to symlink ${src_makedefs}" ; exit 8 ; }
${TOPDIR}/tools/process_config.sh -I ${configpath}/../../common/configs \
  -I ${configpath}/../common -I ${configpath} -o ${dest_config} ${src_config}
install -m 644 ${src_config} "${backup_config}" || \
  { echo "Failed to backup ${src_config}" ; exit 10 ; } #>

  Write-Host "  Copy files" -ForegroundColor Green
  try {
       Copy-Item -Path "$src_makedefs" -Destination "$dest_makedefs"
      } catch {
         Write-Host "Failed to copy file $src_makedefs : $_" -ForegroundColor Red
      }
  try {
       Copy-Item -Path "$src_config" -Destination "$dest_config"
       Copy-Item -Path "$src_config" -Destination "$backup_config"
      } catch {
         Write-Host "Failed to backup $src_config : $_" -ForegroundColor Red
      }


# Install any optional files

<# for opt in ${OPTFILES}; do
  test -f ${configpath}/${opt} && install ${configpath}/${opt} "${TOPDIR}/"
done #>
  foreach ( $opt in $OPTFILES )
  {
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

<# oldnative=`grep CONFIG_WINDOWS_NATIVE= ${src_config} | cut -d'=' -f2`
if [ -z "${oldnative}" ]; then
  oldnative=n
fi
if [ -z "${winnative}" ]; then
  winnative=$oldnative
fi #>

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

<# defappdir=y
if [ -z "${appdir}" -a "X$oldnative" = "X$winnative" ]; then
  quoted=`grep "^CONFIG_APPS_DIR=" ${src_config} | cut -d'=' -f2`
  if [ ! -z "${quoted}" ]; then
    appdir=`echo ${quoted} | sed -e "s/\"//g"`
    defappdir=n
  fi
fi #>

  $defappdir = "y"
  if (($null -eq $appdir) -and ($oldnative -eq $winnative)) {
    $listdefconfig = $null
    $patternallitem = "^CONFIG_APPS_DIR="
    $listdefconfig = $contentdefconfig | Select-String $patternallitem -AllMatches
    $quotedgarr = $listdefconfig -split '='
    Write-Host "quotedgarr: $quotedgarr"
    $quoted = $($quotedgarr[1])
    if ($quoted) {
      $appdir= $quoted -replace '"', ''
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

  # Check for an unversioned apps/ directory

  if [ -d "${TOPDIR}/../apps" ]; then
    appdir="../apps"
  elif [ -d "${TOPDIR}/../nuttx-apps" ]; then
    appdir="../nuttx-apps"
  elif [ -d "${TOPDIR}/../nuttx-apps.git" ]; then
    appdir="../nuttx-apps.git"
  else
    # Check for a versioned apps/ directory

    if [ -d "${TOPDIR}/../apps-${CONFIG_VERSION_STRING}" ]; then
      appdir="../apps-${CONFIG_VERSION_STRING}"
    else
      echo "ERROR: Could not find the path to the appdir"
      exit 7
    fi
  fi
fi #>

# Check for the apps/ directory in the usual place if appdir was not provided
  if ($null -eq $appdir) {
    
    # Check for a version file
# da fare

     # Check for an unversioned apps/ directory

    if (Test-Path -Path "$TOPDIR\..\apps") {
      $appdir="..`\\apps"
      Write-Host "appdir: $appdir" -ForegroundColor Yellow
    } elseif (Test-Path -Path "$TOPDIR\..\nuttx-apps") {
      $appdir="..`\\nuttx-apps"
      Write-Host "appdir: $findval_val" -ForegroundColor Yellow
    } elseif (Test-Path -Path "$TOPDIR\..\nuttx-apps.git") {
      $appdir="..`\\nuttx-apps.git"
      Write-Host "appdir: $appdir" -ForegroundColor Yellow
    } else {
      # Check for a versioned apps/ directory
      if (Test-Path -Path "$TOPDIR\..\apps-$CONFIG_VERSION_STRING") {
         $appdir="..`\\apps-$CONFIG_VERSION_STRING"
         Write-Host "appdir: $appdir" -ForegroundColor Yellow
      } else {  
         Write-Host "ERROR: Could not find the path to the appdir" -ForegroundColor Yellow
         exit 7
      }
    }
  }
# For checking the apps dir path, we need a POSIX version of the relative path.

<# posappdir=`echo "${appdir}" | sed -e 's/\\\\/\\//g'`
winappdir=`echo "${appdir}" | sed -e 's/\\//\\\\\\\/g'` #>


$posappdir= $appdir -replace '\\', '/'
$winappdir= $appdir -replace '/', '\\'

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

<# if [ "X${defappdir}" = "Xy" ]; then
  # In-place edit can mess up permissions on Windows
  # sed -i.bak -e "/^CONFIG_APPS_DIR/d" "${dest_config}"
  sed -e "/^CONFIG_APPS_DIR/d" "${dest_config}" > "${dest_config}-temp"
  mv "${dest_config}-temp" "${dest_config}"

  if [ "X${winnative}" = "Xy" ]; then
    echo "CONFIG_APPS_DIR=\"$winappdir\"" >> "${dest_config}"
  else
    echo "CONFIG_APPS_DIR=\"$posappdir\"" >> "${dest_config}"
  fi
fi #>
<#       fprintf(stream, "\n# Application configuration\n\n");
      fprintf(stream, "CONFIG_APPS_DIR=\"%s\"\n", appdir);

      substitute(boardcfg, '\\', '/');
      fprintf(stream, "CONFIG_BASE_DEFCONFIG=\"%s\"\n", boardcfg);
 #>

if ($defappdir -eq "y") {
    Add-Content -NoNewLine -Path $dest_config -Value "`n# Application configuration`n`n"
  
  if ($winnative -eq "y") {
    # $tmpapps = "CONFIG_APPS_DIR=\`"$winappdir\`"`n"
    Add-Content -NoNewLine -Path "$dest_config" -Value "CONFIG_APPS_DIR=`"$winappdir`"`n"
  } else {
   # $tmpapps = "CONFIG_APPS_DIR=\`"$posappdir\`"`n"
   Add-Content -NoNewLine -Path "$dest_config" -Value "CONFIG_APPS_DIR=`"$posappdir`"`n"
  }
}
# Update the CONFIG_BASE_DEFCONFIG setting

<# posboardconfig=`echo "${boardconfig}" | sed -e 's/\\\\/\\//g'`
echo "CONFIG_BASE_DEFCONFIG=\"$posboardconfig\"" >> "${dest_config}" #>
  #$posboardconfig = "CONFIG_BASE_DEFCONFIG=\`"$posboardconfig\`"`n"
  Add-Content -NoNewLine -Path $dest_config -Value "CONFIG_BASE_DEFCONFIG=`"$boarddir`"`n"


# Select the host build development environment 

function set_host {
   param (
        [string]$host_os,
        [string]$dest_config
    )

switch -regex -casesensitive ($host_os) {
        '-l' {
            $g_host = "HOST_LINUX"
            Break
        }
        '-c' {
            $g_host  = "HOST_WINDOWS"
            $g_windows = "WINDOWS_CYGWIN"
            Break
        }
        '-g' {
            $g_host = "HOST_WINDOWS"
            $g_windows = "WINDOWS_MSYS"
            Break
        }
        '-m' {
            $g_host = "HOST_MACOS"
            Break
        }
        '-n' {
            $g_host = "HOST_WINDOWS"
            $g_windows = "WINDOWS_NATIVE"
            Break
        }
        '-B' {
            $g_host = "HOST_BSD"
            Break
        }
        default {
            Write-Debug "Default $host_os"
            exit 1
        }
}
switch -regex -casesensitive ($g_host) {
        'HOST_LINUX' {
            $g_host = "HOST_LINUX"
            Break
        }
        'HOST_MACOS' {
            $g_host  = "HOST_WINDOWS"
            $g_windows = "WINDOWS_CYGWIN"
            Break
        }
        'HOST_BSD' {
            $g_host = "HOST_WINDOWS"
            $g_windows = "WINDOWS_MSYS"
            Break
        }
        'HOST_WINDOWS' {
          # enable_feature(destconfig, "CONFIG_HOST_WINDOWS");
          kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_HOST_WINDOWS"
          # disable_feature(destconfig, "CONFIG_HOST_LINUX");
          kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_LINUX"
          # disable_feature(destconfig, "CONFIG_HOST_MACOS");
          kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_MACOS"
          # disable_feature(destconfig, "CONFIG_HOST_BSD");
          kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_HOST_BSD"

          # disable_feature(destconfig, "CONFIG_WINDOWS_OTHER");
          kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_OTHER"

          # enable_feature(destconfig, "CONFIG_SIM_X8664_MICROSOFT");
          kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_SIM_X8664_MICROSOFT"
          # disable_feature(destconfig, "CONFIG_SIM_X8664_SYSTEMV");
          kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_SIM_X8664_SYSTEMV"
          # printf("  Select Windows native host\n");
          # disable_feature(destconfig, "CONFIG_WINDOWS_CYGWIN");
          kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_CYGWIN"
          # disable_feature(destconfig, "CONFIG_WINDOWS_MSYS");
          kconfig-tweak.ps1 --file "$dest_config" -d "CONFIG_WINDOWS_MSYS"
          # enable_feature(destconfig, "CONFIG_EXPERIMENTAL");
          kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_EXPERIMENTAL"
          # enable_feature(destconfig, "CONFIG_WINDOWS_NATIVE");
          kconfig-tweak.ps1 --file "$dest_config" -e "CONFIG_WINDOWS_NATIVE"
            Break
        }
        default {
            Write-Debug "Default $g_host"
            exit 1
        }
}
}


# The saved defconfig files are all in compressed format and must be
# reconstitued before they can be used.

<# ${TOPDIR}/tools/sethost.sh $host $* #>
set_host "$host_os" "$dest_config"


 & cmd.exe /C `"make olddefconfig 2`>`&1 `"


# Save the original configuration file without CONFIG_BASE_DEFCONFIG
# for later comparison

<# grep -v "CONFIG_BASE_DEFCONFIG" "${dest_config}" > "${original_config}" #>

  #$tmpcontent = Get-Content -Raw "$dest_config"
  #$tmpcontent = $tmpcontent -replace "CONFIG_BASE_DEFCONFIG=`"$boarddir`"" , ""
  # $tmpcontent = Get-Content -Raw "$dest_config" | Select-String -NotMatch "CONFIG_BASE_DEFCONFIG=`"$boarddir`""
  #$tmpcontent = Get-Content "$dest_config" | Select-String -Pattern "CONFIG_BASE_DEFCONFIG*" -NotMatch
  # Set-Content -Path $original_config -Value "$tmpcontent"
  
  Get-Content "$dest_config" | Select-String -Pattern "CONFIG_BASE_DEFCONFIG*" -NotMatch | %{$_.Line} | Out-File $original_config
