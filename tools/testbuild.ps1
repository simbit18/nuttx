#!/usr/bin/env pswd
############################################################################
# tools/testbuild.ps1
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

$progname = $($MyInvocation.MyCommand.Name)

$WD = Resolve-Path("Get-Location\..\..\..\..")
$nuttx = "$WD\nuttx"
$global:fail = 0
$APPSDIR = "$WD\apps"

if ($null -eq $ARTIFACTDIR) {
  $ARTIFACTDIR = "$WD\buildartifacts"
}
$MAKE = "make"
$HOPTION = $null
$STORE = $null
$JOPTION = $null

$PRINTLISTONLY = 0
$GITCLEAN = 0
$SAVEARTIFACTS = 0
$CHECKCLEAN = 1
$CODECHECKER = 0
$NINJACMAKE = 0
$RUN = 0
$MSVC = 0

function showusage {
  Write-Host ""
  Write-Host "USAGE: $progname -h [-n] [-A] [-G] [-N]"
  Write-Host "Where:"
  Write-Host "  -h will show this help test and terminate"
  Write-Host "  -n selects Windows native"
  Write-Host "  -p only print the list of configs without running any builds"
  Write-Host "  -A store the build executable artifact in ARTIFACTDIR (defaults to ../buildartifacts"
  Write-Host "  -C Skip tree cleanness check."
  Write-Host "  -G Use `"git clean -xfdq`" instead of `"make distclean`" to clean the tree."
  Write-Host "  -N Use CMake with Ninja as the backend."
  Write-Host "  <testlist-file> selects the list of configurations to test.  No default"
  Write-Host ""
  exit 1
}

# Define a function to search for Visual Studio 2022 installation
function Find-VisualStudio {

  # Check common installation paths
  $commonPaths = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Community",
    "C:\Program Files\Microsoft Visual Studio\2022\Professional",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
  )

  foreach ($path in $commonPaths) {
    if (Test-Path $path) {
      $MSVC = 1
    }
  }

  if ($MSVC -eq 1) {
    Write-Host "Found Visual Studio 2022 installations"
    return $MSVC = 1
  }
  else {
    Write-Host "Visual Studio 2022 is not installed on this system."
    return $MSVC = 0
  }

}

$MSVC = Find-VisualStudio

if (!$args[0]) {
  showusage
}
for ( $i = 0; $i -lt $args.count; $i++ ) {
  switch -regex -casesensitive ($($args[$i])) {
    '-h' {
      showusage
    }
    '-n' {
      Write-Host "-c|-g|-l|-m" -ForegroundColor Green
      $HOPTION += " $($args[$i])"
    }
    '-p' {
      $PRINTLISTONLY = 1
    }
    '-j' {
      Write-Host "-j $($args[$i + 1])" -ForegroundColor Green
      $JOPTION = "-j $($args[$i + 1])"
      $i += 1
    }
    '-G' {
      $GITCLEAN = 1
    }
    '-A' {
      $SAVEARTIFACTS = 1
    }
    '-C' {
      $CHECKCLEAN = 0
    }
    '-N' {
      $NINJACMAKE = 1
    }
    '-S' {
      Write-Host "-S" -ForegroundColor Green
      $STORE += " $($args[$i])"
    }
    default {
      Write-Host "File $($args[$i])" -ForegroundColor Green
      $testfile = $($args[$i])
    }
  }
}

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

# Check if apps directory exists
if (-Not (Test-Path -Path $APPSDIR)) {
  Write-Host "ERROR: No directory found at $APPSDIR" -ForegroundColor Red
  exit 1
}

$patternallitem = '^(-|\\)|^[C|c][M|m][A|a][K|k][E|e]'

$patterntestlist = '^\\'

$patternblacklist = '^-'

if ($NINJACMAKE -eq 1) {
  $patterncmakelist = '^[C|c][M|m][A|a][K|k][E|e][,]'
}

$content = Get-Content .\$testfile
$content = $content -replace '/', '\'

Set-Location "$nuttx"

$listfull = $content | Select-String $patternallitem -AllMatches

$testlist = $listfull | Select-String $patterntestlist -AllMatches

$blacklist = $listfull | Select-String $patternblacklist -AllMatches

if ($NINJACMAKE -eq 1) {
  $cmakelist = $listfull | Select-String $patterncmakelist -AllMatches
}

function makefunc {
  param (
    [string]$make_cmd
  )
  try {
    Write-Host "makefunc: Run $MAKE $make_cmd $JOPTION "
    & cmd.exe /C `"$MAKE $make_cmd $JOPTION 2`>`&1 `" # Ok verbose
    # & cmd.exe /C `"$MAKE $make_cmd $JOPTION `>nul 2`>`&1 `"
  }
  catch {
    Write-Host "ERROR: $MAKE failed $_" -ForegroundColor Red
    $global:fail = 1
  }
}

# Clean up after the last build
function distclean {
  Write-Host "  Cleaning..."
  if ((Test-Path ".config") -or (Test-Path "build\.config")) {
    if (($GITCLEAN -eq 1) -or ($cmake)) {
      git -C $nuttx clean -xfdq
      git -C $APPSDIR clean -xfdq
    }
    else {
      makefunc "distclean"
      # Remove .version manually because this file is shipped with
      # the release package and then distclean has to keep it.
      if (Test-Path -Path ".version") {
        Remove-Item ".version" -Force
      }
      if ($CHECKCLEAN -ne 0) {
        if ((Test-Path -Path "$nuttx\.git") -or (Test-Path -Path "$APPSDIR\.git")) {
          try {
            if (git -C $nuttx status --ignored -s 2>$null) {
              git -C $nuttx status --ignored -s
              $global:fail = 1
            }
            if (git -C $APPSDIR status --ignored -s 2>$null) {
              git -C $APPSDIR status --ignored -s
              $global:fail = 1
            }
          }
          catch {
            Write-Host "Git is not installed. Please install Git to use this script." -ForegroundColor Red
            $global:fail = 1
          }
        }
      }
    }
  }
}

function run_command ($command) {
  invoke-expression "$command" *>$null
  Write-Host "run_command $_"
  return $_
}

# Configure for the next build

function configure_default {
  try {
    $tmpconfig = $config -replace '\\', ':'

    if ($tmpconfig -match "windows") {
      Write-Host  "Only Cmake Visual Studio 2022."
    }
    else {
      Write-Host "configure.ps1 $HOPTION $STORE $tmpconfig $JOPTION"
      & .\tools\configure.ps1 $HOPTION $STORE "-j 4" $tmpconfig
    }
    Write-Host "Configuration completed successfully."
  }
  catch {
    Write-Host "Configuration failed: $_"
    $global:fail = 1
  }
   
  if ($toolchain) {
    # Write-Host "CMake toolchain: $toolchain" -ForegroundColor Green
    $patternallitem = '_TOOLCHAIN_'
    $contentconfig = Get-Content "$nuttx\.config"

    $listtoolchain = $contentconfig | Select-String $patternallitem -AllMatches
    # Write-Host "CMake toolchain: $listtoolchain" -ForegroundColor Green
    $listtoolchain = $listtoolchain | Select-String 'CONFIG_TOOLCHAIN_WINDOWS', 'CONFIG_ARCH_TOOLCHAIN_*' -NotMatch | Select-String '=y' -AllMatches
    $toolchainarr = $listtoolchain -split '='
    # Write-Host "toolchainarr: $toolchainarr"
    $original_toolchain = $($toolchainarr[0])
    # Write-Host "original_toolchain: $original_toolchain"
    if ($original_toolchain) {
      Write-Host "  Disabling $original_toolchain"
      kconfig-tweak.ps1 --file "$nuttx\.config" -d $original_toolchain
    }

    Write-Host "  Enabling $toolchain"
    kconfig-tweak.ps1 --file "$nuttx\.config" -e $toolchain
    makefunc "olddefconfig"
  }
  Write-Host "configure_default fail: $global:fail"
}
function configure_cmake {
  # Run CMake with specified configurations

  try {
    $tmpconfig = $config -replace '\\', ':'

    # cmake -B vs2022 -DBOARD_CONFIG=sim/windows -G"Visual Studio 17 2022" -A Win32
    # cmake --build vs2022
    if (($tmpconfig -match "windows") -and ($MSVC -eq 1)) {
      if (cmake -B build -DBOARD_CONFIG="$tmpconfig" -G"Visual Studio 17 2022" -A Win32 1>$null) {
        cmake -B build -DBOARD_CONFIG="$tmpconfig" -G"Visual Studio 17 2022" -A Win32
        $global:fail = 1
      }
    }
    else {
      if (cmake -B build -DBOARD_CONFIG="$tmpconfig" -GNinja 1>$null) {
        cmake -B build -DBOARD_CONFIG="$tmpconfig" -GNinja
        Write-Host "cmake -B build -DBOARD_CONFIG=$tmpconfig -GNinja"
        $global:fail = 1
      }
    }
    Write-Host "  CMake configuration completed successfully."
  }
  catch {
    Write-Host "  CMake configuration failed: $_"
    $global:fail = 1
  }

  if ($toolchain) {
    $patternallitem = '_TOOLCHAIN_'
    $contentconfig = Get-Content "$nuttx\build\.config"

    $listtoolchain = $contentconfig | Select-String $patternallitem -AllMatches
    $listtoolchain = $listtoolchain | Select-String 'CONFIG_TOOLCHAIN_WINDOWS', 'CONFIG_ARCH_TOOLCHAIN_*' -NotMatch | Select-String '=y' -AllMatches
    $toolchainarr = $listtoolchain -split '='
    $original_toolchain = $($toolchainarr[0])

    if ($original_toolchain) {
      Write-Host "  Disabling $original_toolchain"
      kconfig-tweak.ps1 --file "$nuttx\build\.config" -d $original_toolchain
    }

    Write-Host "  Enabling $toolchain"
    kconfig-tweak.ps1 --file "$nuttx\build\.config" -e $toolchain
  }
}

function configure {

  Write-Host "  Configuring..."
  if ($cmake) {
    configure_cmake
  }
  else {
    configure_default
  }

}

# Perform the next build

function build_default {
  makefunc

  if ($SAVEARTIFACTS -eq 1) {
    $artifactconfigdir = "$ARTIFACTDIR\$config"
    Write-Host "Copy in artifactconfigdir: $artifactconfigdir"
    New-Item -Force -ItemType directory -Path $artifactconfigdir > $null
    $contentmanifest = $null
    if (Test-Path -Path "$nuttx\nuttx.manifest") {
      $contentmanifest = Get-Content "$nuttx\nuttx.manifest"
      # Write-Host "Manifest contentmanifest: $contentmanifest"
      # Copy files with error handling
      try {
        foreach ($ma in $contentmanifest) {
          # Write-Host "find manifest: $ma" -ForegroundColor Green
          if (Test-Path -Path "$nuttx\$ma") {
            Copy-Item -Path "$nuttx\$ma" -Destination $artifactconfigdir -Force -ErrorAction Stop
          }
          else {
            Write-Host "build_default: missing file $nuttx\$ma"
          }
        }
        Write-Host "  Files copied successfully from $nuttx to $artifactconfigdir."
      }
      catch {
        Write-Host "An error occurred while copying files: $_" -ForegroundColor Red
      }
    }
  }
}

function build_cmake {

  # Build the project
  try {
    $errorcmakelist = @()
    # $ErrorActionPreference = 'Stop'
    $ErrorActionPreference = "Continue"
    $errorcmakelist = (cmake --build build 2>$null)
    if ($lastExitCode -ne 0) { 
      foreach ($errorline in $errorcmakelist) {
        Write-Host "$errorline"
      }
    }
    else {
      Write-Host "  Build completed successfully."
    }
  }
  catch {
    Write-Error "Build failed: $_"
    $global:fail = 1
  }
  if ($SAVEARTIFACTS -eq 1) {
    $artifactconfigdir = "$ARTIFACTDIR\$config"
    # Write-Host "Copy in artifactconfigdir: $artifactconfigdir"
    New-Item -Force -ItemType directory -Path $artifactconfigdir > $null
    try {
      $contentmanifest = $null
      $contentmanifest = Get-Content "$nuttx\build\nuttx.manifest"
      $tmpconfig = $config -replace '\\', ':'
      if (($tmpconfig -match "windows") -and ($MSVC -eq 1)) {
        Copy-Item -Path "$nuttx\build\Debug\nuttx.exe" -Destination $artifactconfigdir -Force -ErrorAction Stop
        Copy-Item -Path "$nuttx\build\Debug\nuttx.pdb" -Destination $artifactconfigdir -Force -ErrorAction Stop
      }
      else {
        foreach ($ma in $contentmanifest) {
          Copy-Item -Path "$nuttx\build\$ma" -Destination $artifactconfigdir -Force -ErrorAction Stop
        }
      }
    }
    catch {
      Write-Host "  An error occurred while copying files: $_" -ForegroundColor Red
      $global:fail = 1
    }
  }
}

function build {
  Write-Host "  Building NuttX..."
  if ($cmake) {
    # Write-Host "  build_cmake" -ForegroundColor Green
    build_cmake
  }
  else {
    # Write-Host "  build_default to-do" -ForegroundColor Green
    build_default
  }
}

function refresh_default {
  # make refresh_default to-do
}

function refresh_cmake {
  # Ensure defconfig in the canonical form
  if ($toolchain) {
    if ($original_toolchain) {
      kconfig-tweak.ps1 --file "$nuttx\build\.config" -e $original_toolchain
    } 
    kconfig-tweak.ps1 --file "$nuttx\build\.config" -d $toolchain
  }

  try {
    if (cmake --build build -t refreshsilent 1>$null) {
      cmake --build build -t refreshsilent
      $global:fail = 1
    }
    Write-Host "  Refresh completed successfully."
  }
  catch {
    Write-Error "Refresh failed: $_"
    $global:fail = 1
  }

  try {
    Remove-Item build -Recurse -Force
  }
  catch {
    Write-Error "Remove-Item failed: $_"
  }

  # Ensure nuttx and apps directory in clean state

  if ($CHECKCLEAN -ne 0) {
    if ((Test-Path -Path "$nuttx\.git") -or (Test-Path -Path "$APPSDIR\.git")) {
      try {
        if (git -C $nuttx status -s 2>$null) {
          Write-Host "Git $nuttx status " -ForegroundColor Yellow
          git -C $nuttx status -s
          $global:fail = 1
        }
        if (git -C $APPSDIR status -s 2>$null) {
          Write-Host "Git $APPSDIR status " -ForegroundColor Yellow
          git -C $APPSDIR status -s
          $global:fail = 1
        }
      }
      catch {
        Write-Host "Git is not installed. Please install Git to use this script." -ForegroundColor Red
        $global:fail = 1
      }
    }
  }

  # Use -f option twice to remove git sub-repository

  git -C $nuttx clean -f -xfdq
  git -C $APPSDIR clean -f -xfdq
}

function refresh {

  if ($cmake) {
    refresh_cmake
  }
  else {
    # make refresh_default to-do
  }
}

function run {
  # run to-do
}

# Coordinate the steps for the next build test

function dotest {
  param (
    [string]$configfull
  )

  Write-Host "===================================================================================="
  $configarr = $configfull -split ','
  $config = $($configarr[0])

  $check = "Windows," + $config -replace '\\', ':'

  $skip = 0
  foreach ($re in $blacklist) {
    if ("-$check" -eq "$re") {
      $skip = 1
    }
  }

  $cmake = $null
  if ($NINJACMAKE -eq 1) {
    foreach ($l in $cmakelist) {
      if ("Cmake," + $config -replace '\\', ':' -eq "$l") {
        Write-Host "Cmake in present: $config" -ForegroundColor Yellow
        $cmake = 1
      }
    }
  }

  Write-Host "Configuration/Tool: $configfull" -ForegroundColor Yellow
  if ($PRINTLISTONLY -eq 1) {
    return
  }

  $tmparr = $config -split '\\'
  $configdir = $($tmparr[1])

  $boarddir = $($tmparr[0]).Trim()

  
  if (($boarddir -eq "sim") -and ($MSVC -ne 1)) {
    $skip = 1
  }

  $path = "$nuttx\boards\*\*\$boarddir\configs\$configdir"

  if (-Not (Test-Path -Path $path)) {
    Write-Host "ERROR: no configuration found at $path" -ForegroundColor Red
    showusage
  }

  $toolchain = $null
  $original_toolchain = $null
  if ($config -ne $configfull) {
    $toolchain = $($configarr[1])
  }

  Write-Host (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") -ForegroundColor Yellow
  Write-Host "------------------------------------------------------------------------------------"

  distclean
  if ($skip -ne 1 ) {
    configure
    build
    refresh
  }
  else {
    Write-Host "  Skipping: $config" -ForegroundColor Green
  }
}

foreach ($line in $testlist) {

  $firstch = [string[]]$line | ForEach-Object { $_[0] }

  $arr = $line -split ','
  if ($firstch -eq '\') {
    $dir = $arr

    if (!$dir[1]) {
      $cnftoolchain = ""
    }
    else {
      $cnftoolchain = "," + $dir[1]
    }

    $filePath = Get-ChildItem -Path "boards$($dir[0])" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq "defconfig" }
    if ($filePath) {
      foreach ($i in $filePath) {
        $arrpath = $($i.FullName) -split '\\'
        $list = "$($arrpath[$arrpath.count - 4])\$($arrpath[$arrpath.count - 2])"

        dotest "$list$cnftoolchain"
      }
    }
    else {
      Write-Host "File '$FileName' not found in '$list'." -ForegroundColor Yellow
    }
  }
  else {
    dotest "$line"
  }

}

Write-Host "------------------------------------------------------------------------------------"
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Write-Host "End: $timestamp" -ForegroundColor Yellow
Write-Host "===================================================================================="
exit $global:fail
