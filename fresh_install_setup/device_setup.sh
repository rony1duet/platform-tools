#!/system/bin/sh
set -e

echo "==> [1/5] Resizing logical partition filesystems & tuning reserved blocks..."
for blk in dm-0 dm-1 dm-2 dm-3 dm-4; do
    tune2fs -m 0 /dev/block/$blk 2>/dev/null || true
    resize2fs /dev/block/$blk 2>/dev/null || true
done

echo "==> [2/5] Remounting partitions read-write..."
mount -o remount,rw / 2>/dev/null || true
mount -o remount,rw /system_ext 2>/dev/null || true
mount -o remount,rw /product 2>/dev/null || true
mount -o remount,rw /vendor 2>/dev/null || true
mount -o remount,rw /odm 2>/dev/null || true

echo "==> [3/5] Debloating bloatware (Aperture, SafetyHub, FM2, ShinkaiWalls, Stk, DocumentsUI)..."
rm -rf /product/app/Aperture
rm -rf /product/priv-app/SafetyHubPrebuilt
rm -rf /system_ext/app/FM2
rm -rf /system_ext/app/ShinkaiWalls
rm -rf /system_ext/priv-app/MagicPortraitWallpapers
rm -rf /system/app/Stk
rm -rf /system/priv-app/DocumentsUIGoogle
rm -f /product/overlay/DocumentsUIOverlay.apk /product/overlay/PixelDocumentsUIGoogleOverlay_GMS.apk
sync

# Terminate processes holding open deleted descriptors to reclaim blocks immediately
am force-stop com.google.android.apps.wellbeing 2>/dev/null || true
am force-stop com.google.android.apps.safetyhub 2>/dev/null || true
am force-stop org.lineageos.aperture 2>/dev/null || true
pkill -9 -f wellbeing 2>/dev/null || true

# Disable packages for user 0
pm uninstall -k --user 0 org.lineageos.aperture 2>/dev/null || true
pm uninstall -k --user 0 com.google.android.apps.googlecamera.fishfood 2>/dev/null || true
pm uninstall -k --user 0 com.caf.fmradio 2>/dev/null || true
pm uninstall -k --user 0 com.shinkai.wallpapers 2>/dev/null || true
pm uninstall -k --user 0 com.android.stk 2>/dev/null || true
pm uninstall -k --user 0 com.google.android.apps.safetyhub 2>/dev/null || true
pm uninstall com.google.android.documentsui 2>/dev/null || true
pm uninstall -k --user 0 com.google.android.documentsui 2>/dev/null || true
pm uninstall -k --user 0 com.android.documentsui.overlay 2>/dev/null || true
pm uninstall -k --user 0 com.google.android.documentsui.theme.pixel_gms 2>/dev/null || true

echo "==> [4/5] Deploying LunarisDolby system app & permissions..."
mkdir -p /system_ext/priv-app/DolbyManager
mkdir -p /system_ext/etc/permissions

cp /sdcard/fresh_setup/LunarisDolby.apk /system_ext/priv-app/DolbyManager/DolbyManager.apk
chmod 644 /system_ext/priv-app/DolbyManager/DolbyManager.apk
chcon u:object_r:system_file:s0 /system_ext/priv-app/DolbyManager/DolbyManager.apk

cp /sdcard/fresh_setup/privapp-permissions-dolby.xml /system_ext/etc/permissions/privapp-permissions-dolby.xml
chmod 644 /system_ext/etc/permissions/privapp-permissions-dolby.xml
chcon u:object_r:system_file:s0 /system_ext/etc/permissions/privapp-permissions-dolby.xml

rm -rf /system_ext/priv-app/DolbyManager/oat
rm -rf /data/system/package_cache/*co.aospa.dolby* 2>/dev/null || true

echo "==> [5/5] Deploying build.prop templates & installing boot hook..."
cp /sdcard/fresh_setup/props/system.build.prop /system/build.prop
cp /sdcard/fresh_setup/props/system_ext.build.prop /system_ext/etc/build.prop
cp /sdcard/fresh_setup/props/product.build.prop /product/etc/build.prop
cp /sdcard/fresh_setup/props/vendor.build.prop /vendor/build.prop
cp /sdcard/fresh_setup/props/odm.build.prop /odm/etc/build.prop

chmod 644 /system/build.prop /system_ext/etc/build.prop /product/etc/build.prop /vendor/build.prop /odm/etc/build.prop
chcon u:object_r:system_file:s0 /system/build.prop /system_ext/etc/build.prop /product/etc/build.prop
chcon u:object_r:vendor_file:s0 /vendor/build.prop /odm/etc/build.prop

# Install post-fs-data boot hook
mkdir -p /data/adb/post-fs-data.d
cp /sdcard/fresh_setup/01_device_props.sh /data/adb/post-fs-data.d/01_device_props.sh
chmod 755 /data/adb/post-fs-data.d/01_device_props.sh

# Apply immediate live properties safely without resetting USB gadget
RESETPROP="/data/adb/ksu/bin/resetprop"
for p in "" ".system" ".system_ext" ".product" ".vendor" ".odm"; do
    $RESETPROP "ro.product${p}.brand" "Redmi"
    $RESETPROP "ro.product${p}.manufacturer" "Xiaomi"
    $RESETPROP "ro.product${p}.name" "sweet2"
    $RESETPROP "ro.product${p}.model" "Redmi Note 12 Pro"
    $RESETPROP "ro.product${p}.device" "sweet2"
done
$RESETPROP ro.build.product "sweet2"
$RESETPROP ro.custom.device "sweet2"

settings put global device_name "Redmi Note 12 Pro" 2>/dev/null || true
settings put secure bluetooth_name "Redmi Note 12 Pro" 2>/dev/null || true
settings put secure show_rotation_suggestions 0 2>/dev/null || true

echo "==> Device setup phase completed successfully."
