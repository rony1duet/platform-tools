@echo off
setlocal enabledelayedexpansion
title Android Safe Debloater and KernelSU Setup
cd /d "%~dp0"

:: Configure base directories (supports running from root or inside scripts/)
set "BASE_DIR=%~dp0"
if not exist "%BASE_DIR%adb" (
    if exist "%BASE_DIR%..\adb" (
        set "BASE_DIR=%BASE_DIR%..\"
    )
)
set "ADB_DIR=%BASE_DIR%adb"
set "APK_DIR=%BASE_DIR%apk"
set "SCRIPTS_DIR=%BASE_DIR%scripts"

:: Add adb folder to PATH so adb.exe and fastboot.exe execute transparently
if exist "%ADB_DIR%\adb.exe" (
    set "PATH=%ADB_DIR%;!PATH!"
    set "ADB_BIN=%ADB_DIR%\adb.exe"
) else if exist "%BASE_DIR%adb.exe" (
    set "ADB_BIN=%BASE_DIR%adb.exe"
) else (
    set "ADB_BIN=adb.exe"
)

:CHECK_ADB
where adb.exe >nul 2>&1
if errorlevel 1 (
    if not exist "!ADB_BIN!" (
        echo [ERROR] adb.exe was not found in adb/ or current folder!
        echo Please ensure adb.exe and its DLLs are located in the adb/ folder.
        echo.
        pause
        exit /b 1
    )
)

set "CLI_ARG=%~1"

:MENU
if defined CLI_ARG (
    set "choice=%CLI_ARG%"
    set "CLI_MODE=1"
    goto PROCESS_CHOICE
)
cls
echo ================================================================
echo       ANDROID SAFE DEBLOATER ^& KERNELSU SETUP TOOL
echo ================================================================
echo.
echo  [1] FULL AUTOMATION (Install KernelSU + Run Safe Debloat)
echo  [2] Run Safe Debloat Only (Includes Aperture, Bard, OmniJaws, etc.)
echo  [3] Install / Reinstall KernelSU Next Manager APK
echo  [4] Setup Google Camera (MGC) as System App (Replace Aperture)
echo  [5] Restore Debloated Apps
echo  [6] Check Device ^& Root Status
echo  [0] Exit
echo.
echo ================================================================
set "choice="
set /p "choice=Select an option [0-6]: "

:PROCESS_CHOICE
if "%choice%"=="1" goto FULL_SETUP
if "%choice%"=="2" goto RUN_DEBLOAT
if "%choice%"=="3" goto INSTALL_KSU
if "%choice%"=="4" goto SETUP_GCAM
if "%choice%"=="5" goto RESTORE_APPS
if "%choice%"=="6" goto CHECK_STATUS
if "%choice%"=="0" exit /b 0

echo.
echo Invalid choice. Please select a valid number [0-6].
if "%CLI_MODE%"=="1" exit /b 1
ping 127.0.0.1 -n 2 >nul
goto MENU

:WAIT_FOR_DEVICE
echo.
echo [INFO] Looking for connected device via ADB...
adb.exe get-state >nul 2>&1
if errorlevel 1 (
    echo [WARNING] No authorized device detected.
    echo Please ensure:
    echo  1. Your phone is connected via USB cable.
    echo  2. USB Debugging is ENABLED in Developer Options.
    echo  3. You accepted the "Allow USB debugging" prompt on your phone screen.
    echo.
    echo Waiting for device to connect...
    adb.exe wait-for-device
)
echo [OK] Device connected and recognized!
exit /b 0

:DETECT_ROOT
call :WAIT_FOR_DEVICE
set "HAS_ROOT=0"
echo.
echo [INFO] Checking for SuperUser (root) access...
adb.exe shell "su -c id" 2>nul | findstr /i "uid=0" >nul
if not errorlevel 1 (
    set "HAS_ROOT=1"
    echo [OK] Root [su] access verified [uid=0]!
) else (
    echo [INFO] Root [su] not active or not granted to shell.
    echo [INFO] Running in Standard ADB Mode [Root not needed for simple debloat].
)
exit /b 0

:FIND_KSU_APK
set "KSU_APK="
if exist "%APK_DIR%\KernelSU_Next_v3.3.0_33214-release.apk" set "KSU_APK=%APK_DIR%\KernelSU_Next_v3.3.0_33214-release.apk"
if not defined KSU_APK (
    for %%f in ("%APK_DIR%\KernelSU*.apk" "%BASE_DIR%KernelSU*.apk") do (
        if exist "%%~f" set "KSU_APK=%%~f"
    )
)
exit /b 0

:FIND_GCAM_APK
set "GCAM_APK="
if exist "%APK_DIR%\MGC_9.6.080_V51_ENG.apk" set "GCAM_APK=%APK_DIR%\MGC_9.6.080_V51_ENG.apk"
if not defined GCAM_APK (
    for %%f in ("%APK_DIR%\*MGC*.apk" "%APK_DIR%\*GoogleCamera*.apk" "%BASE_DIR%*MGC*.apk" "%USERPROFILE%\Downloads\*MGC*.apk") do (
        if exist "%%~f" set "GCAM_APK=%%~f"
    )
)
exit /b 0

:FULL_SETUP
cls
echo ================================================================
echo               STARTING FULL AUTOMATION SETUP
echo ================================================================
call :WAIT_FOR_DEVICE
call :FIND_KSU_APK

echo.
echo --- Step 1: Installing KernelSU Next Manager APK ---
if defined KSU_APK (
    echo [INFO] Found APK: !KSU_APK!
    adb.exe install -r "!KSU_APK!"
    echo [INFO] Launching KernelSU Manager...
    adb.exe shell monkey -p com.rifsxd.ksunext -c android.intent.category.LAUNCHER 1 >nul 2>&1
    ping 127.0.0.1 -n 2 >nul
) else (
    echo [WARNING] KernelSU APK not found, skipping APK install.
)

echo.
echo --- Step 2: Running Safe Debloat ---
call :DETECT_ROOT

set "DEBLOAT_SCRIPT=%SCRIPTS_DIR%\debloatSu.sh"
if not exist "!DEBLOAT_SCRIPT!" set "DEBLOAT_SCRIPT=%BASE_DIR%debloatSu.sh"

if not exist "!DEBLOAT_SCRIPT!" (
    echo [ERROR] debloatSu.sh script not found!
    if "%CLI_MODE%"=="1" exit /b 1
    pause
    goto MENU
)

adb.exe push "!DEBLOAT_SCRIPT!" /data/local/tmp/debloatSu.sh >nul 2>&1
if "%HAS_ROOT%"=="1" (
    adb.exe shell "su -c 'sh /data/local/tmp/debloatSu.sh'"
) else (
    adb.exe shell "sh /data/local/tmp/debloatSu.sh"
)
adb.exe shell am force-stop com.miui.home >nul 2>&1
adb.exe shell am force-stop com.google.android.apps.nexuslauncher >nul 2>&1
adb.exe shell am force-stop com.android.launcher3 >nul 2>&1
adb.exe shell rm -f /data/local/tmp/debloatSu.sh >nul 2>&1

echo.
echo ================================================================
echo [SUCCESS] Full setup and safe debloat completed successfully!
echo Home screen refreshed.
echo ================================================================
if "%CLI_MODE%"=="1" exit /b 0
pause
goto MENU

:RUN_DEBLOAT
cls
echo ================================================================
echo                 RUNNING SAFE DEBLOAT
echo ================================================================
call :DETECT_ROOT

set "DEBLOAT_SCRIPT=%SCRIPTS_DIR%\debloatSu.sh"
if not exist "!DEBLOAT_SCRIPT!" set "DEBLOAT_SCRIPT=%BASE_DIR%debloatSu.sh"

if not exist "!DEBLOAT_SCRIPT!" (
    echo [ERROR] debloatSu.sh script not found!
    if "%CLI_MODE%"=="1" exit /b 1
    pause
    goto MENU
)

echo.
echo [INFO] Pushing and executing debloat script on phone...
adb.exe push "!DEBLOAT_SCRIPT!" /data/local/tmp/debloatSu.sh >nul 2>&1
if "%HAS_ROOT%"=="1" (
    adb.exe shell "su -c 'sh /data/local/tmp/debloatSu.sh'"
) else (
    adb.exe shell "sh /data/local/tmp/debloatSu.sh"
)
adb.exe shell am force-stop com.miui.home >nul 2>&1
adb.exe shell am force-stop com.google.android.apps.nexuslauncher >nul 2>&1
adb.exe shell am force-stop com.android.launcher3 >nul 2>&1
adb.exe shell rm -f /data/local/tmp/debloatSu.sh >nul 2>&1

echo.
echo [SUCCESS] Debloat script execution finished! Home screen refreshed.
if "%CLI_MODE%"=="1" exit /b 0
pause
goto MENU

:INSTALL_KSU
cls
echo ================================================================
echo             INSTALLING KERNELSU NEXT MANAGER
echo ================================================================
call :WAIT_FOR_DEVICE
call :FIND_KSU_APK

if not defined KSU_APK (
    echo [ERROR] KernelSU Manager APK was not found!
    if "%CLI_MODE%"=="1" exit /b 1
    pause
    goto MENU
)

echo.
echo [INFO] Installing !KSU_APK! via ADB...
adb.exe install -r "!KSU_APK!"
adb.exe shell monkey -p com.rifsxd.ksunext -c android.intent.category.LAUNCHER 1 >nul 2>&1
echo.
echo [SUCCESS] KernelSU Next Manager installation finished.
if "%CLI_MODE%"=="1" exit /b 0
pause
goto MENU

:SETUP_GCAM
cls
echo ================================================================
echo      INSTALLING GOOGLE CAMERA (MGC) AS SYSTEM APP
echo ================================================================
call :DETECT_ROOT
call :FIND_GCAM_APK

set "GCAM_SCRIPT=%SCRIPTS_DIR%\setupGcamModule.sh"
if not exist "!GCAM_SCRIPT!" set "GCAM_SCRIPT=%BASE_DIR%setupGcamModule.sh"

if not exist "!GCAM_SCRIPT!" (
    echo [ERROR] setupGcamModule.sh not found!
    if "%CLI_MODE%"=="1" exit /b 1
    pause
    goto MENU
)

if "%HAS_ROOT%"=="0" (
    echo [ERROR] Root [su] is required to install Google Camera as a system app!
    if "%CLI_MODE%"=="1" exit /b 1
    pause
    goto MENU
)

if defined GCAM_APK (
    echo.
    echo [INFO] Installing !GCAM_APK! via ADB...
    adb.exe install -r -d -g "!GCAM_APK!"
) else (
    echo [INFO] No local GCam APK found, checking existing installation on device...
)

echo.
echo [INFO] Configuring KernelSU Systemless Module for Google Camera...
adb.exe push "!GCAM_SCRIPT!" /data/local/tmp/setupGcamModule.sh >nul 2>&1
adb.exe shell "su -c 'sh /data/local/tmp/setupGcamModule.sh'"
adb.exe shell rm -f /data/local/tmp/setupGcamModule.sh >nul 2>&1

echo.
echo [INFO] Disabling and removing Aperture for current user...
adb.exe shell "pm disable-user --user 0 org.lineageos.aperture 2>/dev/null; pm uninstall -k --user 0 org.lineageos.aperture 2>/dev/null"

adb.exe shell am force-stop com.miui.home >nul 2>&1
adb.exe shell am force-stop com.google.android.apps.nexuslauncher >nul 2>&1
adb.exe shell am force-stop com.android.launcher3 >nul 2>&1

echo.
echo ================================================================
echo [SUCCESS] Google Camera configured as system camera app!
echo Aperture replaced and default camera handlers updated.
echo ================================================================
if "%CLI_MODE%"=="1" exit /b 0
pause
goto MENU

:RESTORE_APPS
cls
echo ================================================================
echo               RESTORING DEBLOATED APPS
echo ================================================================
call :DETECT_ROOT

set "RESTORE_SCRIPT=%SCRIPTS_DIR%\restoreSu.sh"
if not exist "!RESTORE_SCRIPT!" set "RESTORE_SCRIPT=%BASE_DIR%restoreSu.sh"

if not exist "!RESTORE_SCRIPT!" (
    echo [ERROR] restoreSu.sh script not found!
    if "%CLI_MODE%"=="1" exit /b 1
    pause
    goto MENU
)

echo.
echo [INFO] Pushing and executing restore script on phone...
adb.exe push "!RESTORE_SCRIPT!" /data/local/tmp/restoreSu.sh >nul 2>&1
if "%HAS_ROOT%"=="1" (
    adb.exe shell "su -c 'sh /data/local/tmp/restoreSu.sh'"
) else (
    adb.exe shell "sh /data/local/tmp/restoreSu.sh"
)
adb.exe shell am force-stop com.miui.home >nul 2>&1
adb.exe shell am force-stop com.google.android.apps.nexuslauncher >nul 2>&1
adb.exe shell am force-stop com.android.launcher3 >nul 2>&1
adb.exe shell rm -f /data/local/tmp/restoreSu.sh >nul 2>&1

echo.
echo [SUCCESS] Restore operation finished! Home screen refreshed.
if "%CLI_MODE%"=="1" exit /b 0
pause
goto MENU

:CHECK_STATUS
cls
echo ================================================================
echo                  DEVICE ^& ROOT STATUS
echo ================================================================
call :WAIT_FOR_DEVICE
echo.
echo [1] Device Information:
for /f "tokens=*" %%a in ('adb.exe shell getprop ro.product.model') do echo  - Model: %%a
for /f "tokens=*" %%a in ('adb.exe shell getprop ro.product.device') do echo  - Device Codename: %%a
for /f "tokens=*" %%a in ('adb.exe shell getprop ro.build.version.release') do echo  - Android Version: %%a
for /f "tokens=*" %%a in ('adb.exe shell getprop ro.modversion 2^>nul') do echo  - Custom ROM Version: %%a
for /f "tokens=*" %%a in ('adb.exe shell getprop ro.build.display.id 2^>nul') do echo  - Build Display ID: %%a

echo.
echo [2] Root (su) Status:
adb.exe shell "su -c id" 2>nul
if errorlevel 1 (
    echo  - Root [su] is not active or not granted to shell.
)

echo.
echo [3] KernelSU Manager Status:
adb.exe shell pm list packages | findstr /i "ksunext kernelsu"
if errorlevel 1 (
    echo  - KernelSU Manager application is not installed.
)

echo.
echo [4] KernelSU CLI ^& Modules:
adb.exe shell "su -c '/data/adb/ksud -V 2>/dev/null; /data/adb/ksud module list 2>/dev/null'"

echo.
echo [5] Default System Camera:
adb.exe shell "cmd package resolve-activity --brief -a android.media.action.STILL_IMAGE_CAMERA"
echo.
if "%CLI_MODE%"=="1" exit /b 0
pause
goto MENU
