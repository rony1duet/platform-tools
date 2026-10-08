#!/system/bin/sh
set -e

echo "================================================================"
echo " Setting up Lunaris Dolby Atmos via KernelSU Module"
echo "================================================================"

MODDIR="/data/adb/modules/lunaris_dolby_atmos"
rm -rf "$MODDIR"
mkdir -p "$MODDIR/system/system_ext/priv-app/LunarisDolby"
mkdir -p "$MODDIR/system/system_ext/priv-app/DolbyManager"
mkdir -p "$MODDIR/system/system_ext/etc/permissions"
mkdir -p "$MODDIR/system/system_ext/etc/sysconfig"
mkdir -p "$MODDIR/system/product/overlay/DolbyManager__custom_sweet2__auto_generated_rro_product"
mkdir -p "$MODDIR/system/product/overlay"
mkdir -p "$MODDIR/system/vendor/etc/dolby"
mkdir -p "$MODDIR/system/vendor/etc/vintf/manifest"
mkdir -p "$MODDIR/common"

# Mask out stock Dolby app & overlay
touch "$MODDIR/system/system_ext/priv-app/DolbyManager/.replace"
touch "$MODDIR/system/product/overlay/DolbyManager__custom_sweet2__auto_generated_rro_product/.replace"

# Find source APK
BASE_APK=""
for cand in /data/local/tmp/LunarisDolby.apk /data/local/tmp/*Dolby*.apk; do
    if [ -f "$cand" ]; then
        BASE_APK="$cand"
        break
    fi
done

if [ -z "$BASE_APK" ] || [ ! -f "$BASE_APK" ]; then
    echo "[ERROR] LunarisDolby APK was not found in /data/local/tmp!"
    exit 1
fi

echo "[INFO] Source APK: $BASE_APK"
cp "$BASE_APK" "$MODDIR/system/system_ext/priv-app/LunarisDolby/LunarisDolby.apk"
cp "$BASE_APK" "$MODDIR/common/LunarisDolby.apk"

# Copy configs if staged in /data/local/tmp
[ -f /data/local/tmp/privapp-permissions-dolby.xml ] && cp /data/local/tmp/privapp-permissions-dolby.xml "$MODDIR/system/system_ext/etc/permissions/"
[ -f /data/local/tmp/preinstalled-packages-platform-dolby.xml ] && cp /data/local/tmp/preinstalled-packages-platform-dolby.xml "$MODDIR/system/system_ext/etc/sysconfig/"
[ -f /data/local/tmp/DolbyFrameworksResCommon.apk ] && cp /data/local/tmp/DolbyFrameworksResCommon.apk "$MODDIR/system/product/overlay/"
[ -f /data/local/tmp/dax-default.xml ] && cp /data/local/tmp/dax-default.xml "$MODDIR/system/vendor/etc/dolby/"
[ -f /data/local/tmp/media_codecs_dolby_audio.xml ] && cp /data/local/tmp/media_codecs_dolby_audio.xml "$MODDIR/system/vendor/etc/"
[ -f /data/local/tmp/vendor.dolby.hardware.dms@2.0-service.xml ] && cp /data/local/tmp/vendor.dolby.hardware.dms@2.0-service.xml "$MODDIR/system/vendor/etc/vintf/manifest/"
[ -f /data/local/tmp/vendor.dolby.media.c2.xml ] && cp /data/local/tmp/vendor.dolby.media.c2.xml "$MODDIR/system/vendor/etc/vintf/manifest/"

# Disable stock co.aospa.dolby
echo "[INFO] Disabling stock co.aospa.dolby..."
pm disable-user --user 0 co.aospa.dolby >/dev/null 2>&1 || true
pm uninstall -k --user 0 co.aospa.dolby >/dev/null 2>&1 || true
pm disable-user --user 0 co.aospa.dolby.auto_generated_rro_product__ >/dev/null 2>&1 || true
pm uninstall -k --user 0 co.aospa.dolby.auto_generated_rro_product__ >/dev/null 2>&1 || true

# Install APK into PackageManager
echo "[INFO] Registering Lunaris Dolby Atmos APK in PackageManager..."
pm install -r -d -g "$BASE_APK" >/dev/null 2>&1 || pm install -r "$BASE_APK" >/dev/null 2>&1 || true

# Grant permissions and appops
echo "[INFO] Granting required audio routing and recording permissions..."
pm grant org.lunaris.dolby android.permission.MODIFY_AUDIO_ROUTING >/dev/null 2>&1 || true
pm grant org.lunaris.dolby android.permission.RECORD_AUDIO >/dev/null 2>&1 || true
appops set org.lunaris.dolby GET_USAGE_STATS allow >/dev/null 2>&1 || true

# Write module.prop
cat << 'EOF' > "$MODDIR/module.prop"
id=lunaris_dolby_atmos
name=Lunaris Dolby Atmos
version=1.0
versionCode=100
author=MD RONY HOSSEN (rony1duet)
description=Lunaris Dolby Atmos with modern Compose Material 3 UI for AOSP custom ROMs. Replaces stock co.aospa.dolby. Maintained by rony1duet.
EOF

# Write service.sh
cat << 'EOF' > "$MODDIR/service.sh"
#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 2
done

# Ensure stock co.aospa.dolby remains suppressed
pm disable-user --user 0 co.aospa.dolby >/dev/null 2>&1 || true
pm disable-user --user 0 co.aospa.dolby.auto_generated_rro_product__ >/dev/null 2>&1 || true

# Install LunarisDolby APK if missing
if ! pm path org.lunaris.dolby >/dev/null 2>&1; then
  APK_CAND=""
  if [ -f "$MODDIR/system/system_ext/priv-app/LunarisDolby/LunarisDolby.apk" ]; then
    APK_CAND="$MODDIR/system/system_ext/priv-app/LunarisDolby/LunarisDolby.apk"
  elif [ -f "$MODDIR/system_ext/priv-app/LunarisDolby/LunarisDolby.apk" ]; then
    APK_CAND="$MODDIR/system_ext/priv-app/LunarisDolby/LunarisDolby.apk"
  elif [ -f "$MODDIR/common/LunarisDolby.apk" ]; then
    APK_CAND="$MODDIR/common/LunarisDolby.apk"
  fi
  if [ -n "$APK_CAND" ]; then
    pm install -r -d -g "$APK_CAND" >/dev/null 2>&1 || pm install -r "$APK_CAND" >/dev/null 2>&1 || true
  fi
fi

# Ensure LunarisDolby permissions and appops
pm grant org.lunaris.dolby android.permission.MODIFY_AUDIO_ROUTING >/dev/null 2>&1 || true
pm grant org.lunaris.dolby android.permission.RECORD_AUDIO >/dev/null 2>&1 || true
appops set org.lunaris.dolby GET_USAGE_STATS allow >/dev/null 2>&1 || true
EOF

chmod -R 755 "$MODDIR"
chmod 644 "$MODDIR/module.prop"
chmod 755 "$MODDIR/service.sh"
find "$MODDIR/system" -type f -exec chmod 644 {} + 2>/dev/null || true
find "$MODDIR/system" -type d -exec chmod 755 {} + 2>/dev/null || true
chown -R root:root "$MODDIR"
chcon -R u:object_r:system_file:s0 "$MODDIR/system" 2>/dev/null || true

echo "================================================================"
echo " [SUCCESS] Lunaris Dolby Atmos Module configured successfully!"
echo "================================================================"
if [ -x "/data/adb/ksud" ]; then
    /data/adb/ksud module list
fi
