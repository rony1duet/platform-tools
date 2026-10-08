#!/system/bin/sh
set -e

echo "================================================================"
echo " Setting up Google Camera (MGC) as System App via KernelSU"
echo "================================================================"

MODDIR="/data/adb/modules/gcam_system"
rm -rf "$MODDIR"
mkdir -p "$MODDIR/system/product/app/GoogleCameraEng/lib/arm64"
mkdir -p "$MODDIR/system/product/app/Aperture"
mkdir -p "$MODDIR/system/product/app/ApertureLensLauncher"

# Mask out stock system camera apps
touch "$MODDIR/system/product/app/Aperture/.replace"
touch "$MODDIR/system/product/app/ApertureLensLauncher/.replace"

cat << 'EOF' > "$MODDIR/module.prop"
id=gcam_system
name=Google Camera (MGC) System App
version=9.6.080
versionCode=96080
author=BSG / MGC (rony1duet)
description=Systemlessly installs Google Camera (MGC 9.6.080) with 64-bit native libraries and Sweet (Redmi Note 10 Pro) tuning, replacing stock Aperture camera.
EOF

# Find source APK
BASE_APK=$(pm path com.google.android.GoogleCameraEng 2>/dev/null | head -n 1 | sed 's/package://')
if [ -z "$BASE_APK" ] || [ ! -f "$BASE_APK" ]; then
    for cand in /data/local/tmp/*MGC*ENG*.apk /data/local/tmp/MGC*.apk /data/local/tmp/GoogleCameraEng.apk /data/local/tmp/*MGC*.apk; do
        if [ -f "$cand" ]; then
            BASE_APK="$cand"
            break
        fi
    done
fi

if [ -z "$BASE_APK" ] || [ ! -f "$BASE_APK" ]; then
    echo "[ERROR] GoogleCameraEng APK was not found on device!"
    exit 1
fi

echo "[INFO] Source APK: $BASE_APK"
cp "$BASE_APK" "$MODDIR/system/product/app/GoogleCameraEng/GoogleCameraEng.apk"

# Copy or extract 64-bit native libraries
LIB_DIR="$(dirname "$BASE_APK")/lib/arm64"
if [ -d "$LIB_DIR" ] && [ "$(ls -A "$LIB_DIR" 2>/dev/null)" ]; then
    echo "[INFO] Copying native libraries from $LIB_DIR..."
    cp -a "$LIB_DIR"/* "$MODDIR/system/product/app/GoogleCameraEng/lib/arm64/"
else
    echo "[INFO] Extracting native libraries from APK..."
    unzip -j -o "$BASE_APK" "lib/arm64-v8a/*.so" -d "$MODDIR/system/product/app/GoogleCameraEng/lib/arm64/" >/dev/null 2>&1 || true
fi

# Set proper permissions and SELinux contexts
chmod -R 755 "$MODDIR"
chmod 644 "$MODDIR/module.prop"
find "$MODDIR/system" -type f -exec chmod 644 {} +
find "$MODDIR/system" -type d -exec chmod 755 {} +
chown -R root:root "$MODDIR"
chcon -R u:object_r:system_file:s0 "$MODDIR/system" 2>/dev/null || true

# Import & Inject GCam XML Configuration if available
CONFIG_SRC="/data/local/tmp/GCam_Config.xml"
if [ ! -f "$CONFIG_SRC" ]; then
    for cand in /data/local/tmp/GCam_Config*.xml /data/local/tmp/*sweet*.xml; do
        if [ -f "$cand" ]; then
            CONFIG_SRC="$cand"
            break
        fi
    done
fi

if [ -f "$CONFIG_SRC" ]; then
    echo "[INFO] Importing GCam XML configuration: $CONFIG_SRC"
    mkdir -p /sdcard/GCam/Configs9
    mkdir -p /sdcard/GCam/Configs8
    mkdir -p /sdcard/Download
    cp "$CONFIG_SRC" /sdcard/GCam/Configs9/GCam_Config_sweet_k6a.xml 2>/dev/null || true
    cp "$CONFIG_SRC" /sdcard/GCam/Configs8/GCam_Config_sweet_k6a.xml 2>/dev/null || true
    cp "$CONFIG_SRC" /sdcard/Download/GCam_Config_sweet_k6a.xml 2>/dev/null || true
    cp "$CONFIG_SRC" /sdcard/Download/MGC.cfg 2>/dev/null || true

    PREFS_DIR="/data/data/com.google.android.GoogleCameraEng/shared_prefs"
    if [ -d "/data/data/com.google.android.GoogleCameraEng" ]; then
        mkdir -p "$PREFS_DIR"
        GCAM_UID=$(stat -c "%u" /data/data/com.google.android.GoogleCameraEng 2>/dev/null || echo "10000")
        cp "$CONFIG_SRC" "$PREFS_DIR/com.google.android.GoogleCameraEng_preferences.xml"
        chown -R "$GCAM_UID:$GCAM_UID" "$PREFS_DIR" 2>/dev/null || true
        chmod 660 "$PREFS_DIR/com.google.android.GoogleCameraEng_preferences.xml" 2>/dev/null || true
        restorecon -R /data/data/com.google.android.GoogleCameraEng 2>/dev/null || true
        echo "[SUCCESS] Configuration applied directly to camera preferences!"
    fi
    rm -f "$CONFIG_SRC" 2>/dev/null || true
fi

echo "================================================================"
echo " [SUCCESS] KernelSU Module & GCam Config configured successfully!"
echo "================================================================"
if [ -x "/data/adb/ksud" ]; then
    /data/adb/ksud module list
fi
