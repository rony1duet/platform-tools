#!/system/bin/sh
set -e

echo "================================================================"
echo " Setting up System Safe Debloat via KernelSU Module"
echo "================================================================"

MODDIR="/data/adb/modules/system_safe_debloat"
rm -rf "$MODDIR"
mkdir -p "$MODDIR/system/product/app/VoiceAccessPrebuilt"
mkdir -p "$MODDIR/system/product/priv-app/RecorderPrebuilt_847964105"
mkdir -p "$MODDIR/system/system_ext/app/OmniJaws"

# Systemlessly mask out unwanted bloatware apps
touch "$MODDIR/system/product/app/VoiceAccessPrebuilt/.replace"
touch "$MODDIR/system/product/priv-app/RecorderPrebuilt_847964105/.replace"
touch "$MODDIR/system/system_ext/app/OmniJaws/.replace"

cat << 'EOF' > "$MODDIR/module.prop"
id=system_safe_debloat
name=System Safe Debloat
version=1.0
versionCode=100
author=Md Rony Hossen (rony1duet)
description=Systemlessly debloats bloatware apps for EvolutionX OS (OmniJaws, VoiceAccess, Recorder) via overlayfs masking.
EOF

chmod -R 755 "$MODDIR"
chmod 644 "$MODDIR/module.prop"
find "$MODDIR/system" -type f -exec chmod 644 {} +
find "$MODDIR/system" -type d -exec chmod 755 {} +
chown -R root:root "$MODDIR"
chcon -R u:object_r:system_file:s0 "$MODDIR/system" 2>/dev/null || true

echo "================================================================"
echo " [SUCCESS] System Safe Debloat Module configured successfully!"
echo "================================================================"
if [ -x "/data/adb/ksud" ]; then
    /data/adb/ksud module list
fi
