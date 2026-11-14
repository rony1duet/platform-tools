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

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Redmi Note 12 Pro (sweet2) - Fresh Setup Provisioner" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Check ADB
if (-not (Test-Path $AdbPath)) {
    $AdbPath = "adb.exe"
}

Write-Host "[1/7] Checking ADB connection..." -ForegroundColor Yellow
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

# 2. Online Filesystem Expansion & Remount RW
Write-Host "[2/7] Expanding partition filesystems & remounting RW..." -ForegroundColor Yellow
& $AdbPath shell @"
resize2fs /dev/block/dm-0 2>/dev/null
resize2fs /dev/block/dm-1 2>/dev/null
resize2fs /dev/block/dm-2 2>/dev/null
resize2fs /dev/block/dm-3 2>/dev/null
resize2fs /dev/block/dm-4 2>/dev/null

mount -o remount,rw / 2>/dev/null
mount -o remount,rw /system_ext 2>/dev/null
mount -o remount,rw /product 2>/dev/null
mount -o remount,rw /vendor 2>/dev/null
mount -o remount,rw /odm 2>/dev/null
"@
Write-Host "[✓] Partitions expanded and mounted read-write" -ForegroundColor Green

# 3. System Debloat (Partition cleanup + Package manager disable)
Write-Host "[3/7] Debloating system apps (Aperture, SafetyHub, FM2, ShinkaiWalls, Stk)..." -ForegroundColor Yellow
& $AdbPath shell @"
# Stop processes holding file descriptors
am force-stop com.google.android.apps.wellbeing 2>/dev/null
am force-stop com.google.android.apps.safetyhub 2>/dev/null
am force-stop org.lineageos.aperture 2>/dev/null

# Backup directory
mkdir -p /data/adb/backup/debloat

# Remove partition bloatware to free space
[ -d /product/app/Aperture ] && cp -a /product/app/Aperture /data/adb/backup/debloat/ 2>/dev/null && rm -rf /product/app/Aperture
[ -d /product/priv-app/SafetyHubPrebuilt ] && cp -a /product/priv-app/SafetyHubPrebuilt /data/adb/backup/debloat/ 2>/dev/null && rm -rf /product/priv-app/SafetyHubPrebuilt
[ -d /system_ext/app/FM2 ] && cp -a /system_ext/app/FM2 /data/adb/backup/debloat/ 2>/dev/null && rm -rf /system_ext/app/FM2
[ -d /system_ext/app/ShinkaiWalls ] && cp -a /system_ext/app/ShinkaiWalls /data/adb/backup/debloat/ 2>/dev/null && rm -rf /system_ext/app/ShinkaiWalls
[ -d /system_ext/priv-app/MagicPortraitWallpapers ] && cp -a /system_ext/priv-app/MagicPortraitWallpapers /data/adb/backup/debloat/ 2>/dev/null && rm -rf /system_ext/priv-app/MagicPortraitWallpapers
[ -d /system/app/Stk ] && cp -a /system/app/Stk /data/adb/backup/debloat/ 2>/dev/null && rm -rf /system/app/Stk

# Uninstall/Disable for user 0
pm uninstall -k --user 0 org.lineageos.aperture 2>/dev/null
pm uninstall -k --user 0 com.google.android.apps.googlecamera.fishfood 2>/dev/null
pm uninstall -k --user 0 com.caf.fmradio 2>/dev/null
pm uninstall -k --user 0 com.shinkai.wallpapers 2>/dev/null
pm uninstall -k --user 0 com.android.stk 2>/dev/null
pm uninstall -k --user 0 com.google.android.apps.safetyhub 2>/dev/null
"@
Write-Host "[✓] Bloatware cleanly removed and disabled" -ForegroundColor Green

# 4. Deploy LunarisDolby System Integration
Write-Host "[4/7] Deploying LunarisDolby (co.aospa.dolby) system app..." -ForegroundColor Yellow
$dolbyApk = Join-Path $FilesDir "LunarisDolby.apk"
$dolbyPerm = Join-Path $FilesDir "privapp-permissions-dolby.xml"

& $AdbPath push $dolbyApk /sdcard/DolbyManager.apk
& $AdbPath push $dolbyPerm /sdcard/privapp-permissions-dolby.xml

& $AdbPath shell @"
mkdir -p /system_ext/priv-app/DolbyManager
mkdir -p /system_ext/etc/permissions

cp /sdcard/DolbyManager.apk /system_ext/priv-app/DolbyManager/DolbyManager.apk
chmod 644 /system_ext/priv-app/DolbyManager/DolbyManager.apk
chcon u:object_r:system_file:s0 /system_ext/priv-app/DolbyManager/DolbyManager.apk

cp /sdcard/privapp-permissions-dolby.xml /system_ext/etc/permissions/privapp-permissions-dolby.xml
chmod 644 /system_ext/etc/permissions/privapp-permissions-dolby.xml
chcon u:object_r:system_file:s0 /system_ext/etc/permissions/privapp-permissions-dolby.xml

rm -rf /system_ext/priv-app/DolbyManager/oat
rm -rf /data/system/package_cache/*co.aospa.dolby* 2>/dev/null
rm -f /sdcard/DolbyManager.apk /sdcard/privapp-permissions-dolby.xml
"@
Write-Host "[✓] LunarisDolby installed to /system_ext/priv-app/ with privapp permissions" -ForegroundColor Green

# 5. Install GCam V52 & Config
Write-Host "[5/7] Installing GCam V52 & staging custom config..." -ForegroundColor Yellow
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

Write-Host "  -> Pushing custom config..."
& $AdbPath shell "mkdir -p /sdcard/GCam/Configs9 /sdcard/Download"
& $AdbPath push $gcamXml /sdcard/GCam/Configs9/BSG_9.6_Pixel_8_v260423.xml
& $AdbPath push $gcamXml /sdcard/Download/BSG_9.6_Pixel_8_v260423.xml

& $AdbPath shell @"
pm grant com.google.android.GoogleCameraEng android.permission.CAMERA 2>/dev/null
pm grant com.google.android.GoogleCameraEng android.permission.RECORD_AUDIO 2>/dev/null
pm grant com.google.android.GoogleCameraEng android.permission.ACCESS_FINE_LOCATION 2>/dev/null
pm grant com.google.android.GoogleCameraEng android.permission.ACCESS_COARSE_LOCATION 2>/dev/null
pm grant com.google.android.GoogleCameraEng android.permission.READ_MEDIA_IMAGES 2>/dev/null
pm grant com.google.android.GoogleCameraEng android.permission.READ_MEDIA_VIDEO 2>/dev/null
pm grant com.google.android.GoogleCameraEng android.permission.READ_MEDIA_AUDIO 2>/dev/null
appops set com.google.android.GoogleCameraEng MANAGE_EXTERNAL_STORAGE allow 2>/dev/null
"@
Write-Host "[✓] GCam V52 and BSG XML config configured" -ForegroundColor Green

# 6. Apply Device Props & Fix Rotation Suggestions Button
Write-Host "[6/7] Setting Model (Redmi Note 12 Pro), Codename (sweet2), & disabling rotate pill..." -ForegroundColor Yellow

# Push patched build.prop files
& $AdbPath push (Join-Path $PropsDir "system.build.prop") /sdcard/system.build.prop
& $AdbPath push (Join-Path $PropsDir "system_ext.build.prop") /sdcard/system_ext.build.prop
& $AdbPath push (Join-Path $PropsDir "product.build.prop") /sdcard/product.build.prop
& $AdbPath push (Join-Path $PropsDir "vendor.build.prop") /sdcard/vendor.build.prop
& $AdbPath push (Join-Path $PropsDir "odm.build.prop") /sdcard/odm.build.prop

& $AdbPath shell @"
cp /sdcard/system.build.prop /system/build.prop
chmod 644 /system/build.prop
chcon u:object_r:system_file:s0 /system/build.prop

cp /sdcard/system_ext.build.prop /system_ext/etc/build.prop
chmod 644 /system_ext/etc/build.prop
chcon u:object_r:system_file:s0 /system_ext/etc/build.prop

cp /sdcard/product.build.prop /product/etc/build.prop
chmod 644 /product/etc/build.prop
chcon u:object_r:system_file:s0 /product/etc/build.prop

cp /sdcard/vendor.build.prop /vendor/build.prop
chmod 644 /vendor/build.prop
chcon u:object_r:vendor_file:s0 /vendor/build.prop

cp /sdcard/odm.build.prop /odm/etc/build.prop
chmod 644 /odm/etc/build.prop
chcon u:object_r:vendor_file:s0 /odm/etc/build.prop

rm -f /sdcard/*.build.prop

# Install boot script in /data/adb/post-fs-data.d
mkdir -p /data/adb/post-fs-data.d
cat << 'EOF' > /data/adb/post-fs-data.d/01_device_props.sh
#!/system/bin/sh
RESETPROP="/data/adb/ksu/bin/resetprop"

# Brand & Manufacturer
\$RESETPROP ro.product.brand "Redmi"
\$RESETPROP ro.product.system.brand "Redmi"
\$RESETPROP ro.product.system_ext.brand "Redmi"
\$RESETPROP ro.product.product.brand "Redmi"
\$RESETPROP ro.product.vendor.brand "Redmi"
\$RESETPROP ro.product.odm.brand "Redmi"

\$RESETPROP ro.product.manufacturer "Xiaomi"
\$RESETPROP ro.product.system.manufacturer "Xiaomi"
\$RESETPROP ro.product.system_ext.manufacturer "Xiaomi"
\$RESETPROP ro.product.product.manufacturer "Xiaomi"
\$RESETPROP ro.product.vendor.manufacturer "Xiaomi"
\$RESETPROP ro.product.odm.manufacturer "Xiaomi"

# Name
\$RESETPROP ro.product.name "sweet2"
\$RESETPROP ro.product.system.name "sweet2"
\$RESETPROP ro.product.system_ext.name "sweet2"
\$RESETPROP ro.product.product.name "sweet2"
\$RESETPROP ro.product.vendor.name "sweet2"
\$RESETPROP ro.product.odm.name "sweet2"

# Model
\$RESETPROP ro.product.model "Redmi Note 12 Pro"
\$RESETPROP ro.product.system.model "Redmi Note 12 Pro"
\$RESETPROP ro.product.system_ext.model "Redmi Note 12 Pro"
\$RESETPROP ro.product.product.model "Redmi Note 12 Pro"
\$RESETPROP ro.product.vendor.model "Redmi Note 12 Pro"
\$RESETPROP ro.product.odm.model "Redmi Note 12 Pro"
\$RESETPROP ro.product.system_dlkm.model "Redmi Note 12 Pro"
\$RESETPROP ro.product.vendor_dlkm.model "Redmi Note 12 Pro"
\$RESETPROP ro.product.odm_dlkm.model "Redmi Note 12 Pro"
\$RESETPROP ro.product.marketname "Redmi Note 12 Pro"

# Device / Codename
\$RESETPROP ro.product.device "sweet2"
\$RESETPROP ro.product.system.device "sweet2"
\$RESETPROP ro.product.system_ext.device "sweet2"
\$RESETPROP ro.product.product.device "sweet2"
\$RESETPROP ro.product.vendor.device "sweet2"
\$RESETPROP ro.product.odm.device "sweet2"
\$RESETPROP ro.product.system_dlkm.device "sweet2"
\$RESETPROP ro.product.vendor_dlkm.device "sweet2"
\$RESETPROP ro.product.odm_dlkm.device "sweet2"
\$RESETPROP ro.build.product "sweet2"
\$RESETPROP ro.custom.device "sweet2"

# USB String
\$RESETPROP vendor.usb.product_string "Redmi Note 12 Pro"

# Disable floating rotation suggestions button (lockscreen rotate button)
settings put secure show_rotation_suggestions 0
EOF
chmod 755 /data/adb/post-fs-data.d/01_device_props.sh

# Apply immediate live resetprop
/data/adb/ksu/bin/resetprop ro.product.brand "Redmi"
/data/adb/ksu/bin/resetprop ro.product.system.brand "Redmi"
/data/adb/ksu/bin/resetprop ro.product.system_ext.brand "Redmi"
/data/adb/ksu/bin/resetprop ro.product.product.brand "Redmi"
/data/adb/ksu/bin/resetprop ro.product.vendor.brand "Redmi"
/data/adb/ksu/bin/resetprop ro.product.odm.brand "Redmi"

/data/adb/ksu/bin/resetprop ro.product.manufacturer "Xiaomi"
/data/adb/ksu/bin/resetprop ro.product.system.manufacturer "Xiaomi"
/data/adb/ksu/bin/resetprop ro.product.system_ext.manufacturer "Xiaomi"
/data/adb/ksu/bin/resetprop ro.product.product.manufacturer "Xiaomi"
/data/adb/ksu/bin/resetprop ro.product.vendor.manufacturer "Xiaomi"
/data/adb/ksu/bin/resetprop ro.product.odm.manufacturer "Xiaomi"

/data/adb/ksu/bin/resetprop ro.product.name "sweet2"
/data/adb/ksu/bin/resetprop ro.product.system.name "sweet2"
/data/adb/ksu/bin/resetprop ro.product.system_ext.name "sweet2"
/data/adb/ksu/bin/resetprop ro.product.product.name "sweet2"
/data/adb/ksu/bin/resetprop ro.product.vendor.name "sweet2"
/data/adb/ksu/bin/resetprop ro.product.odm.name "sweet2"

/data/adb/ksu/bin/resetprop ro.product.model "Redmi Note 12 Pro"
/data/adb/ksu/bin/resetprop ro.product.system.model "Redmi Note 12 Pro"
/data/adb/ksu/bin/resetprop ro.product.system_ext.model "Redmi Note 12 Pro"
/data/adb/ksu/bin/resetprop ro.product.product.model "Redmi Note 12 Pro"
/data/adb/ksu/bin/resetprop ro.product.vendor.model "Redmi Note 12 Pro"
/data/adb/ksu/bin/resetprop ro.product.odm.model "Redmi Note 12 Pro"
/data/adb/ksu/bin/resetprop ro.product.device "sweet2"
/data/adb/ksu/bin/resetprop ro.product.system.device "sweet2"
/data/adb/ksu/bin/resetprop ro.product.system_ext.device "sweet2"
/data/adb/ksu/bin/resetprop ro.product.product.device "sweet2"
/data/adb/ksu/bin/resetprop ro.product.vendor.device "sweet2"
/data/adb/ksu/bin/resetprop ro.product.odm.device "sweet2"
/data/adb/ksu/bin/resetprop vendor.usb.product_string "Redmi Note 12 Pro"

# Disable rotation suggestions
settings put secure show_rotation_suggestions 0
"@
Write-Host "[✓] Device properties patched and lockscreen rotation button disabled" -ForegroundColor Green

# 7. Restart Framework
Write-Host "[7/7] Restarting zygote to reload framework..." -ForegroundColor Yellow
& $AdbPath shell "setprop ctl.restart zygote"
Start-Sleep -Seconds 6
& $AdbPath wait-for-device
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE! Device is fully configured." -ForegroundColor Green
Write-Host "  Model: Redmi Note 12 Pro | Codename: sweet2" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
