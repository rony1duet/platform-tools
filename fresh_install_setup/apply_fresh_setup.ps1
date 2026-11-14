# ==============================================================================
# Redmi Note 12 Pro (sweet2 / sweet_k6a) - Fresh Install Turnkey Provisioner
# PixelOS / Shinkai ROM Post-Reset Automation Script
# ==============================================================================

param(
    [string]$AdbPath = "C:\Program Files\platform-tools\adb.exe"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FilesDir = Join-Path $ScriptDir "files"
$PropsDir = Join-Path $FilesDir "props"
$DeviceScript = Join-Path $ScriptDir "device_setup.sh"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Redmi Note 12 Pro (sweet2) - Fresh Setup Provisioner" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Check ADB
if (-not (Test-Path $AdbPath)) {
    $AdbPath = "adb.exe"
}

Write-Host "[1/6] Checking ADB connection..." -ForegroundColor Yellow
& $AdbPath wait-for-device
$devs = & $AdbPath devices
Write-Host $devs

# Check root
$rootCheck = & $AdbPath shell "id -u"
if ($rootCheck.Trim() -ne "0") {
    Write-Host "[!] Root access (uid 0) required! Ensure KernelSU is active." -ForegroundColor Red
    exit 1
}
Write-Host "[✓] Device authorized with root (uid 0)" -ForegroundColor Green

# 2. Stage Setup Files to Device
Write-Host "[2/6] Staging deployment files to /sdcard/fresh_setup/..." -ForegroundColor Yellow
& $AdbPath shell "rm -rf /sdcard/fresh_setup && mkdir -p /sdcard/fresh_setup/props"
& $AdbPath push $DeviceScript /sdcard/fresh_setup/device_setup.sh
& $AdbPath push (Join-Path $FilesDir "01_device_props.sh") /sdcard/fresh_setup/01_device_props.sh
& $AdbPath push (Join-Path $FilesDir "LunarisDolby.apk") /sdcard/fresh_setup/LunarisDolby.apk
& $AdbPath push (Join-Path $FilesDir "privapp-permissions-dolby.xml") /sdcard/fresh_setup/privapp-permissions-dolby.xml
& $AdbPath push (Join-Path $PropsDir "system.build.prop") /sdcard/fresh_setup/props/system.build.prop
& $AdbPath push (Join-Path $PropsDir "system_ext.build.prop") /sdcard/fresh_setup/props/system_ext.build.prop
& $AdbPath push (Join-Path $PropsDir "product.build.prop") /sdcard/fresh_setup/props/product.build.prop
& $AdbPath push (Join-Path $PropsDir "vendor.build.prop") /sdcard/fresh_setup/props/vendor.build.prop
& $AdbPath push (Join-Path $PropsDir "odm.build.prop") /sdcard/fresh_setup/props/odm.build.prop
Write-Host "[✓] All files staged successfully" -ForegroundColor Green

# 3. Execute On-Device Configuration Script
Write-Host "[3/6] Running on-device partition resize, debloat, Dolby, and build.prop installer..." -ForegroundColor Yellow
& $AdbPath shell "sh /sdcard/fresh_setup/device_setup.sh"
& $AdbPath wait-for-device
Write-Host "[✓] On-device configuration completed" -ForegroundColor Green

# 4. Install GCam V52 & Config
Write-Host "[4/6] Installing GCam V52 APK & staging BSG XML config..." -ForegroundColor Yellow
$gcamApk = Join-Path $FilesDir "MGC_9.6.080_V52_ENG.apk"
if (-not (Test-Path $gcamApk)) {
    $parentApk = Join-Path (Split-Path $ScriptDir -Parent) "apk\MGC_9.6.080_V52_ENG.apk"
    if (Test-Path $parentApk) {
        $gcamApk = $parentApk
    }
}
$gcamXml = Join-Path $FilesDir "BSG_9.6_Pixel_8_v260423.xml"

Write-Host "  -> Installing GCam APK from $gcamApk..."
& $AdbPath install -r -d -g $gcamApk

Write-Host "  -> Staging custom config..."
& $AdbPath shell "mkdir -p /sdcard/GCam/Configs9 /sdcard/Download"
& $AdbPath push $gcamXml /sdcard/GCam/Configs9/BSG_9.6_Pixel_8_v260423.xml
& $AdbPath push $gcamXml /sdcard/Download/BSG_9.6_Pixel_8_v260423.xml

& $AdbPath shell "
pm grant com.google.android.GoogleCameraEng android.permission.CAMERA 2>/dev/null || true
pm grant com.google.android.GoogleCameraEng android.permission.RECORD_AUDIO 2>/dev/null || true
pm grant com.google.android.GoogleCameraEng android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true
pm grant com.google.android.GoogleCameraEng android.permission.ACCESS_COARSE_LOCATION 2>/dev/null || true
pm grant com.google.android.GoogleCameraEng android.permission.READ_MEDIA_IMAGES 2>/dev/null || true
pm grant com.google.android.GoogleCameraEng android.permission.READ_MEDIA_VIDEO 2>/dev/null || true
pm grant com.google.android.GoogleCameraEng android.permission.READ_MEDIA_AUDIO 2>/dev/null || true
appops set com.google.android.GoogleCameraEng MANAGE_EXTERNAL_STORAGE allow 2>/dev/null || true
"
Write-Host "[✓] GCam V52 configured and permissions granted" -ForegroundColor Green

# 5. Cleanup Staged Files
Write-Host "[5/6] Cleaning up staging folder..." -ForegroundColor Yellow
& $AdbPath shell "rm -rf /sdcard/fresh_setup"
Write-Host "[✓] Temporary staging cleaned" -ForegroundColor Green

# 6. Restart Framework
Write-Host "[6/6] Restarting zygote to reload framework..." -ForegroundColor Yellow
& $AdbPath shell "setprop ctl.restart zygote"
Start-Sleep -Seconds 6
& $AdbPath wait-for-device

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE! Device is fully configured." -ForegroundColor Green
Write-Host "  Brand: Redmi | Model: Redmi Note 12 Pro | Codename: sweet2" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
