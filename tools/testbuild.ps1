#!/usr/bin/env pswd
# tools/testbuild.ps1
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

# Set-PSDebug -Trace 0

# Write-Host "Run testbuild.ps1 !!!" -ForegroundColor Yellow
# Write-Host "======================"
$CID = Get-Location
# Write-Host "The CID path $CID" -ForegroundColor Green
$WD=Resolve-Path("Get-Location\..\..\..\..")
# Write-Host "The WD path $WD" -ForegroundColor Green
$nuttx="$WD\nuttx"
# Write-Host "The nuttx path $nuttx" -ForegroundColor Green
$global:fail=0
$APPSDIR="$WD\apps"
# Write-Host "The apps path $APPSDIR" -ForegroundColor Green

if ($null -eq $ARTIFACTDIR) {
  $ARTIFACTDIR="$WD\buildartifacts"
  # Write-Host "The path ARTIFACTDIR: $ARTIFACTDIR" -ForegroundColor Green
}

$PRINTLISTONLY=0
$GITCLEAN=0
$SAVEARTIFACTS=0
$CHECKCLEAN=1
$CODECHECKER=0
$NINJACMAKE=0
$RUN=0
$MSVC=0

function showusage {
    Write-Host ""
    Write-Host "====================" -ForegroundColor Cyan
    Write-Host "      Run Menu      " -ForegroundColor Yellow
    Write-Host "====================" -ForegroundColor Cyan
    Write-Host "USAGE: $progname -h [-n] [-A] [-G] [-N]"
    Write-Host "Where:"
    Write-Host "  -h will show this help test and terminate"
    Write-Host "  -n selects Windows native"
    Write-Host "  -p only print the list of configs without running any builds"
    Write-Host "  -A store the build executable artifact in ARTIFACTDIR (defaults to ../buildartifacts"
    Write-Host "  -C Skip tree cleanness check."
    Write-Host "  -G Use \"git clean -xfdq\" instead of \"make distclean\" to clean the tree."
    Write-Host "  -N Use CMake with Ninja as the backend."
    Write-Host "  <testlist-file> selects the list of configurations to test.  No default"
    Write-Host ""
    exit 1
}

function Test-GitVersion ($version = $([string](git --version 2>$null))) {
    if ($version -notmatch '(?<ver>\d+(?:\.\d+)+)(?<g4w>(?<rc>[-.]rc\d+)?\.windows|\.vfs)?') {
        Write-Warning "posh-git could not parse Git version ($version)"
    }
}

# Define a function to search for Visual Studio 2022 installation
function Find-VisualStudio {
    # Initialize an array to hold found installations
    $foundInstallations = @()

    # Check common installation paths
    $commonPaths = @(
        "C:\Program Files\Microsoft Visual Studio\2022\Community",
        "C:\Program Files\Microsoft Visual Studio\2022\Professional",
        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $MSVC=1
        }
    }

    if ($MSVC -eq 1) {
        # Write-Output "Found Visual Studio 2022 installations"
        Write-Host "Found Visual Studio 2022 installations"
        return $MSVC=1
    } else {
        # Write-Output "Visual Studio 2022 is not installed on this system."
        Write-Host "Visual Studio 2022 is not installed on this system."
        return $MSVC=0
    }

}
# Function to check if CMake exists
function Check-CMake {
    # Try to get the CMake executable path
    $cmakePath = Get-Command cmake -ErrorAction SilentlyContinue

    if ($null -eq $cmakePath) {
        Write-Host "CMake is not installed on this system." -ForegroundColor Red
    }
    else {
        Write-Host "CMake is installed at: $($cmakePath.Source)" -ForegroundColor Green
        
        # Get the version of CMake
        $versionInfo = & cmake --version
        Write-Host "CMake version information:" -ForegroundColor Cyan
        Write-Host $versionInfo
    }
}

# Main script execution

# Check-CMake
$MSVC=Find-VisualStudio
# Write-Host "MSVC $MSVC." -ForegroundColor Red

# Test-GitVersion
# write-host "There are a total of $($args.count) arguments"
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
        '-p' {
            # Write-Host "-p" -ForegroundColor Green
            $PRINTLISTONLY=1
        }
        '-G' {
            # Write-Host "-G" -ForegroundColor Green
            $GITCLEAN=1
        }
        '-A' {
            # Write-Host "-A" -ForegroundColor Green
            $SAVEARTIFACTS=1
        }
        '-C' {
            # Write-Host "-C" -ForegroundColor Green
            $CHECKCLEAN=0
        }
        '-N' {
            # Write-Host "-N" -ForegroundColor Green
            $NINJACMAKE=1
        }
        default {
            Write-Host "File $($args[$i])" -ForegroundColor Green
            $testfile=$($args[$i])
        }
    }
}

# Write-Host "NINJACMAKE: $NINJACMAKE"
# Write-Host "SAVEARTIFACTS: $SAVEARTIFACTS"


# Check if testfile file exists
if (-not (Test-Path -Path "$testfile")) {
   Write-Host "ERROR: Missing test list file"  -ForegroundColor Red
   showusage
}
# Check if nuttx directory exists
if (-Not (Test-Path -Path $nuttx)) {
    Write-Host "ERROR: Expected to find nuttx/ at $nuttx" -ForegroundColor Red
    showusage
}

# Check if source directory exists
if (-Not (Test-Path -Path $APPSDIR)) {
    Write-Host "ERROR: No directory found at $APPSDIR" -ForegroundColor Red
    exit 1
}

$patternallitem = '^(-|\\)|^[C|c][M|m][A|a][K|k][E|e]'

$patterntestlist = '^\\'

$patternblacklist = '^-'

if ($NINJACMAKE -eq 1) {
  # Write-Host "NINJACMAKE $NINJACMAKE -----" -ForegroundColor Yellow
  $patterncmakelist = '^[C|c][M|m][A|a][K|k][E|e][,]'
}

$content = Get-Content .\$testfile
$content = $content -replace '/', '\'
#-------------------------

Set-Location "$nuttx"

#$listfull = @()
$listfull = $content | Select-String $patternallitem -AllMatches
<# foreach($linea in $testlist) {
    Write-Host "pattern2a: $linea" -ForegroundColor Green
} #>
#$testlist = @()
$testlist = $listfull | Select-String $patterntestlist -AllMatches
<# foreach($linea in $testlist) {
    Write-Host "pattern2t: $linea" -ForegroundColor Green
} #>

#$blacklist = @()
$blacklist = $listfull | Select-String $patternblacklist -AllMatches

<# foreach($linea in $blacklist) {
    Write-Host "pattern2b: $linea" -ForegroundColor Green
} #>

if ($NINJACMAKE -eq 1) {
  #$cmakelist = @()
  $cmakelist = $listfull | Select-String $patterncmakelist -AllMatches
  <# foreach($linea in $cmakelist) {
      Write-Host "pattern2c: $linea" -ForegroundColor Green
  } #>
}


# Clean up after the last build
#to-do test
function distclean {
  Write-Host "  Cleaning..."
  if ((Test-Path ".config") -or (Test-Path "build\.config")) {
     if (($GITCLEAN -eq 1) -or ($cmake)) {
        git -C $nuttx clean -xfdq
        #Write-Host "distclean: git -C $nuttx clean -xfdq"
        git -C $APPSDIR clean -xfdq
        Write-Host "git -C $APPSDIR clean -xfdq"
     } else {
        # Remove .version manually because this file is shipped with
        # the release package and then distclean has to keep it.
        if ($CHECKCLEAN -ne 0) {
          if ((Test-Path -Path "$nuttx\.git") -or (Test-Path -Path "$APPSDIR\.git")) {
            Write-Host "distclean Git CHECKCLEAN" -ForegroundColor Red
            try {
              if (git -C $nuttx status --ignored -s 2>$null) {
                git -C $nuttx status --ignored -s
                Write-Host "distclean: Git $nuttx status --ignored"
                $global:fail = 1
              }
              if (git -C $APPSDIR status --ignored -s 2>$null) {
                git -C $APPSDIR status --ignored -s
                Write-Host "distclean: Git $APPSDIR status --ignored"
                $global:fail = 1
              }
            } catch {
              Write-Host "Git is not installed. Please install Git to use this script." -ForegroundColor Red
              $global:fail = 1
            }
          }
        }
     }
  }
  Write-Host "distclean fail: $global:fail"
  # return $global:fail
}

function run_command ($command)
{
    invoke-expression "$command" *>$null
    Write-Host "run_command $_"
    return $_
}

function configure_cmake {
  # Run CMake with specified configurations

  try {
    $tmpconfig=$config -replace '\\', ':'

    # cmake -B vs2022 -DBOARD_CONFIG=sim/windows -G"Visual Studio 17 2022" -A Win32
    # cmake --build vs2022
    if ($tmpconfig -match "windows") {
      Write-Host "CMake vs2022: $tmpconfig"
      if ($MSVC -eq 1) {
        Write-Host  "Found Visual Studio 2022 installations"
        if (cmake -B build -DBOARD_CONFIG="$tmpconfig" -G"Visual Studio 17 2022" -A Win32 1>$null) {
            cmake -B build -DBOARD_CONFIG="$tmpconfig" -G"Visual Studio 17 2022" -A Win32
            $global:fail=1
        }
      } else {
        Write-Host  "Visual Studio 2022 is not installed on this system."
      }
    } else {
      #if (!(run_command "cmake -B build -DBOARD_CONFIG=$tmpconfig -GNinja")) {
      if (cmake -B build -DBOARD_CONFIG="$tmpconfig" -GNinja 1> $null) {
         cmake -B build -DBOARD_CONFIG="$tmpconfig" -GNinja
         Write-Host "cmake -B build -DBOARD_CONFIG=$tmpconfig -GNinja"
         $global:fail=1
         
      }
    }
    Write-Host "CMake configuration completed successfully."
  } catch {
    # Write-Error "CMake configuration failed: $_"
    Write-Host "CMake configuration failed: $_"
    $global:fail=1
  }
   
  if ($toolchain) {
      # Write-Host "CMake toolchain: $toolchain" -ForegroundColor Green
      $patternallitem = '_TOOLCHAIN_'
      $contentconfig = Get-Content "$nuttx\build\.config"

      $listtoolchain = $contentconfig | Select-String $patternallitem -AllMatches
      # Write-Host "CMake toolchain: $listtoolchain" -ForegroundColor Green
      $listtoolchain = $listtoolchain | Select-String 'CONFIG_TOOLCHAIN_WINDOWS', 'CONFIG_ARCH_TOOLCHAIN_*' -NotMatch | Select-String '=y' -AllMatches
      # Write-Host "CMake toolchain: $listtoolchain" -ForegroundColor Green
      $toolchainarr = $listtoolchain -split '='
      # Write-Host "toolchainarr: $toolchainarr"
      $original_toolchain = $($toolchainarr[0])
      # Write-Host "original_toolchain: $original_toolchain"
      if ($original_toolchain) {
        Write-Host "  Disabling $original_toolchain"
        kconfig-tweak.ps1 --file "$nuttx\build\.config" -d $original_toolchain
      }

      Write-Host "  Enabling $toolchain"
      kconfig-tweak.ps1 --file "$nuttx\build\.config" -e $toolchain
  }
  Write-Host "configure_cmake fail: $global:fail"
  # return $global:fail

}

function configure {

  Write-Host "  Configuring..."
  if ($cmake) {
    # Write-Host "  configure_cmake" -ForegroundColor Green
    configure_cmake
  } else {
    #Write-Host "  configure_default" -ForegroundColor Green
  }
  
}


# Perform the next build

function build_default {
<#   if [ "${CODECHECKER}" -eq 1 ]; then
    checkfunc
  else
    makefunc
  fi

  if [ ${SAVEARTIFACTS} -eq 1 ]; then
    artifactconfigdir=$ARTIFACTDIR/$(echo $config | sed "s/:/\//")/
    mkdir -p $artifactconfigdir
    xargs -I "{}" cp "{}" $artifactconfigdir < $nuttx/nuttx.manifest
  fi

  return $fail #>
}

function build_cmake {

  # Build the project
  try {
    if (cmake --build build 1> $null) {
        cmake --build build
        $global:fail=1
    }
    Write-Host "Build completed successfully."
  } catch {
    Write-Error "Build failed: $_"
    $global:fail=1
  }
  if ($SAVEARTIFACTS -eq 1) {
    $artifactconfigdir="$ARTIFACTDIR\$config"
    Write-Host "Copy in artifactconfigdir: $artifactconfigdir"
    New-Item -Force -ItemType directory -Path $artifactconfigdir > $null
    $contentmanifest = $null
    $contentmanifest = Get-Content "$nuttx\build\nuttx.manifest"
    # Write-Host "Manifest contentmanifest: $contentmanifest"
    # Copy files with error handling
    try {
        foreach($ma in $contentmanifest) {
          # Write-Host "find manifest: $ma" -ForegroundColor Green
          Copy-Item -Path "$nuttx\build\$ma" -Destination $artifactconfigdir -Force -ErrorAction Stop
        }
        #Copy-Item -Path "$Source\*" -Destination $Destination -Recurse -Force -ErrorAction Stop
        Write-Host "Files copied successfully from $nuttx\build to $artifactconfigdir."
    } catch {
        Write-Host "An error occurred while copying files: $_" -ForegroundColor Red
    }
  }
  Write-Host "build_cmake fail: $global:fail"
}

function build {
  
  Write-Host "  Building NuttX..."
  if ($cmake) {
    Write-Host "  build_cmake" -ForegroundColor Green
    build_cmake
  } else {
    Write-Host "  build_default" -ForegroundColor Green
  }
}

function refresh_default {
<#   # Ensure defconfig in the canonical form

  if ! ./tools/refresh.sh --silent $config; then
    fail=1
  fi

  # Ensure nuttx and apps directory in clean state

  if [ ${CHECKCLEAN} -ne 0 ]; then
    if [ -d $nuttx/.git ] || [ -d $APPSDIR/.git ]; then
      if [[ -n $(git -C $nuttx status -s) ]]; then
        git -C $nuttx status
        fail=1
      fi
      if [[ -n $(git -C $APPSDIR status -s) ]]; then
        git -C $APPSDIR status
        fail=1
      fi
    fi
  fi

  return $fail #>
}

function refresh_cmake {
  # Ensure defconfig in the canonical form
  if ($toolchain) {
      # Write-Host "CMake toolchain: $toolchain." -ForegroundColor Green
     if ($original_toolchain) {
        # Write-Host "kconfig-tweak  Enable: $original_toolchain" -ForegroundColor Green
        kconfig-tweak.ps1 --file "$nuttx\build\.config" -e $original_toolchain
      } 
        # Write-Host "kconfig-tweak  Disable: $toolchain" -ForegroundColor Green
        kconfig-tweak.ps1 --file "$nuttx\build\.config" -d $toolchain
  }
  
  try {
    if (cmake --build build -t refreshsilent 1> $null) {
        cmake --build build -t refreshsilent
        $global:fail=1
    }
    Write-Host "refreshsilent completed successfully."
  } catch {
    Write-Error "refreshsilent failed: $_"
    $global:fail=1
  }

  # rm -rf build
  try {
    # Write-Host "Remove-Item build -Force."
    Remove-Item build -Recurse -Force
  } catch {
    Write-Error "Remove-Item failed: $_"
  }
  
    # Ensure nuttx and apps directory in clean state

  if ($CHECKCLEAN -ne 0) {
    if ((Test-Path -Path "$nuttx\.git") -or (Test-Path -Path "$APPSDIR\.git")){
      # Write-Host "Git OK" -ForegroundColor Red
      try {
           if (git -C $nuttx status -s 2> $null) {
              Write-Host "Git $nuttx status " -ForegroundColor Yellow
              git -C $nuttx status -s
              $global:fail=1
           }
           if (git -C $APPSDIR status -s 2> $null) {
              Write-Host "Git $APPSDIR status " -ForegroundColor Yellow
              git -C $APPSDIR status -s
              $global:fail=1
           }
      } catch {
          Write-Host "Git is not installed. Please install Git to use this script." -ForegroundColor Red
          $global:fail=1
      }
    }
  }

  # Use -f option twice to remove git sub-repository

  git -C $nuttx clean -f -xfdq
  git -C $APPSDIR clean -f -xfdq
  Write-Host "refresh_cmake fail: $global:fail"
}

function refresh {

  if ($cmake) {
    # Write-Host "  refresh_cmake" -ForegroundColor Green
    refresh_cmake
  } else {
    # Write-Host "  refresh_default" -ForegroundColor Green
  }
  
}

function run {
<#   if [ ${RUN} -ne 0 ] && [ -z ${cmake} ]; then
    run_script="$path/run"
    if [ -x $run_script ]; then
      echo "  Running NuttX..."
      if ! $run_script; then
        fail=1
      fi
    fi
  fi
  return $fail #>
}

# Coordinate the steps for the next build test

function dotest {
   param (
        [string]$configfull
    )

  Write-Host "===================================================================================="
  # Write-Host "configfull: $configfull"
  $configarr = $configfull -split ','
  # Write-Host "configarr: $configarr"
  $config=$($configarr[0])
  # Write-Host "config: $config"

  $check="Windows," + $config -replace '\\', ':'
  # Write-Host "check: $check"
  
 # config=`echo $1 | cut -d',' -f1`
 # check=${HOST},${config/\//:}

  $skip=0
  foreach($re in $blacklist) {
    # Write-Host "find blacklist: $re" -ForegroundColor Green
    if ("-$check" -eq "$re") {
      Write-Host "Skipping: $configfull"
      $skip=1
    }
  }

  $cmake = $null
  if ($NINJACMAKE -eq 1) {
    # Write-Host "OK $NINJACMAKE -----" -ForegroundColor Yellow
    foreach($l in $cmakelist) {
      # Write-Host "find cmake: $l" -ForegroundColor Green
      if ("Cmake," + $config -replace '\\', ':' -eq "$l") {
        # Write-Host "Cmake in present: $configfull" -ForegroundColor Green
        $cmake=1
      }
    }
  }

  Write-Host "Configuration/Tool: $configfull" -ForegroundColor Yellow
  if ($PRINTLISTONLY -eq 1) {
    return
  }

  $tmparr = $config -split '\\' #$($configarr[0].Split("\\")) # $($configarr[0] -split ':')
  $configdir=$($tmparr[1])
  # Write-Host "configdir: $configdir"
  
  $boarddir=$($tmparr[0]).Trim()
  # Write-Host "boarddir: $boarddir"
  
  if (($boarddir -eq "sim") -and ($MSVC -ne 1)) {
    Write-Host "Skipping: boarddir $boarddir MSVC: $MSVC"
    Write-Host "Skipping: $configfull"
    $skip=1
  }

  $path="$nuttx\boards\*\*\$boarddir\configs\$configdir"
  # Write-Host "path: $path"
  if (-Not (Test-Path -Path $path)) {
    Write-Host "ERROR: no configuration found at $path" -ForegroundColor Red
    showusage
  }

  $toolchain = $null
  $original_toolchain = $null
  if ($config -ne $configfull) {
    $toolchain=$($configarr[1])
    # Write-Host "toolchain '$toolchain'"
  }

  Write-Host (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")  -ForegroundColor Yellow
  Write-Host "------------------------------------------------------------------------------------"
  distclean
  if ($skip -ne 1 ) {
    configure
    build
    refresh
  } else {
    Write-Host "  Skipping: $config" -ForegroundColor Green
  }
}


# Write-Host "There are a total of $($testlist.count) arguments."
# Write-Host " Start ..."

foreach($line in $testlist) {
    # Write-Host "Find config: $line" -ForegroundColor Green

    $firstch = [string[]]$line | ForEach-Object { $_[0] }

    $arr = $line -split ','
    if ($firstch -eq '\') {
        $dir = $arr
        # Write-Host "dir: $($dir[0])"
        # Write-host "dir: There are a total of $($dir.count) arguments"
        
        if (!$dir[1]) {
          $cnftoolchain=""
        } else {
          $cnftoolchain="," + $dir[1]
        }
        # Write-host "cnftoolchain: $cnftoolchain"

       # Searching for the file
       # Write-Host "Searching for the path boards: boards$($dir[0])" -ForegroundColor Green
       $filePath = Get-ChildItem -Path "boards$($dir[0])" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "defconfig" }
       if ($filePath) {
        #Write-Host "File found: $($filePath.FullName)" -ForegroundColor Green
        foreach($i in $filePath) {
          $arrpath = $($i.FullName) -split '\\'
          # Write-host "arrpath: There are a total of $($arrpath.count) arguments"
          # Write-Host "File found: $($arrpath)" -ForegroundColor Green
          # Write-Host "File found: $($arrpath[$arrpath.count - 4]):$($arrpath[$arrpath.count - 2])" -ForegroundColor Green
          $list="$($arrpath[$arrpath.count - 4])\$($arrpath[$arrpath.count - 2])"
          # Write-Host "list: $list"
          dotest "$list$cnftoolchain"
        }

       } else {
         Write-Host "File '$FileName' not found in '$list'." -ForegroundColor Yellow
       }
    } else {
        Write-Host "Skipping to-do: $line"
        dotest "$line"
    }

}

##Set-Location "$CID"
#####
# $global:fail=0
Write-Host "fail: $global:fail"
Write-Host "===================================================================================="
# dir $ARTIFACTDIR
exit $global:fail