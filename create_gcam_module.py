import os
import shutil
import zipfile

base_dir = os.path.dirname(os.path.abspath(__file__))
mod_dir = os.path.join(base_dir, 'GCam_System_Module')
if os.path.exists(mod_dir):
    shutil.rmtree(mod_dir)

# 1. Directory Structure
meta_dir = os.path.join(mod_dir, 'META-INF', 'com', 'google', 'android')
os.makedirs(meta_dir, exist_ok=True)

gcam_app_dir = os.path.join(mod_dir, 'system', 'product', 'app', 'GoogleCameraEng')
gcam_lib_dir = os.path.join(gcam_app_dir, 'lib', 'arm64')
os.makedirs(gcam_lib_dir, exist_ok=True)

aperture_dir = os.path.join(mod_dir, 'system', 'product', 'app', 'Aperture')
aperture_lens_dir = os.path.join(mod_dir, 'system', 'product', 'app', 'ApertureLensLauncher')
os.makedirs(aperture_dir, exist_ok=True)
os.makedirs(aperture_lens_dir, exist_ok=True)

common_dir = os.path.join(mod_dir, 'common')
os.makedirs(common_dir, exist_ok=True)

# 2. Mask stock camera apps with .replace
with open(os.path.join(aperture_dir, '.replace'), 'w') as f:
    pass
with open(os.path.join(aperture_lens_dir, '.replace'), 'w') as f:
    pass

import sys
sys.path.insert(0, os.path.join(base_dir, 'scripts'))
from download_gcam import ensure_gcam_apk

# 3. Copy APK & extract 64-bit native libraries
src_apk = ensure_gcam_apk(os.path.join(base_dir, 'apk'))
dest_apk = os.path.join(gcam_app_dir, 'GoogleCameraEng.apk')
print(f"Staging GoogleCameraEng APK from {src_apk}...")
shutil.copy2(src_apk, dest_apk)

# Determine version for module.prop
version_str = "9.6.080"
apk_basename = os.path.basename(src_apk)
if 'MGC_' in apk_basename:
    v_cand = apk_basename.split('MGC_')[-1].replace('_ENG.apk', '').replace('.apk', '')
    if v_cand:
        version_str = v_cand

print("Extracting 64-bit native libraries (lib/arm64-v8a/*.so)...")
with zipfile.ZipFile(src_apk, 'r') as zf:
    for member in zf.namelist():
        if member.startswith('lib/arm64-v8a/') and member.endswith('.so'):
            so_filename = os.path.basename(member)
            target_path = os.path.join(gcam_lib_dir, so_filename)
            with zf.open(member) as src_file, open(target_path, 'wb') as dst_file:
                shutil.copyfileobj(src_file, dst_file)

# 4. Copy GCam XML config
src_config = os.path.join(base_dir, 'apk', 'GCam_Config_sweet_k6a.xml')
dest_config = os.path.join(common_dir, 'GCam_Config_sweet_k6a.xml')
shutil.copy2(src_config, dest_config)

# 5. updater-script
with open(os.path.join(meta_dir, 'updater-script'), 'w', newline='\n') as f:
    f.write('#MAGISK\n')

# 6. update-binary
update_binary_content = '''#!/sbin/sh
#################
# Initialization
#################
umask 022

ui_print() { echo "$1"; }

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk/KernelSU!"
  ui_print "*******************************"
  exit 1
}

OUTFD=$2
ZIPFILE=$3

mount /data 2>/dev/null

if [ -f /data/adb/magisk/util_functions.sh ]; then
  . /data/adb/magisk/util_functions.sh
elif [ -f /data/adb/ksu/util_functions.sh ]; then
  . /data/adb/ksu/util_functions.sh
elif [ -f /data/adb/ap/util_functions.sh ]; then
  . /data/adb/ap/util_functions.sh
else
  [ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
  . /data/adb/magisk/util_functions.sh
fi

install_module
exit 0
'''
with open(os.path.join(meta_dir, 'update-binary'), 'w', newline='\n') as f:
    f.write(update_binary_content)

# 7. module.prop
module_prop_content = f'''id=gcam_system
name=Google Camera (MGC) System App
version={version_str}
versionCode=96080
author=BSG / MGC (rony1duet)
description=Systemlessly installs Google Camera (MGC {version_str}) with 64-bit native libraries and Sweet (Redmi Note 10 Pro) tuning, replacing stock Aperture camera.
'''
with open(os.path.join(mod_dir, 'module.prop'), 'w', newline='\n') as f:
    f.write(module_prop_content)

# 8. customize.sh
customize_content = '''ui_print "**************************************************"
ui_print "      Google Camera (MGC) System App Module       "
ui_print "      Tuned for Redmi Note 10 Pro (sweet)         "
ui_print "      Maintained by Md Rony Hossen (rony1duet)    "
ui_print "**************************************************"

ui_print "- Masking stock Aperture camera..."
pm disable-user --user 0 org.lineageos.aperture >/dev/null 2>&1
pm uninstall -k --user 0 org.lineageos.aperture >/dev/null 2>&1

ui_print "- Setting module permissions..."
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/system/product/app/GoogleCameraEng/GoogleCameraEng.apk 0 0 0644
set_perm_recursive $MODPATH/system/product/app/GoogleCameraEng/lib 0 0 0755 0644

ui_print "- Importing Sweet (k6a) GCam XML Configuration..."
CONFIG_FILE="$MODPATH/common/GCam_Config_sweet_k6a.xml"
if [ -f "$CONFIG_FILE" ]; then
  mkdir -p /sdcard/GCam/Configs9
  mkdir -p /sdcard/GCam/Configs8
  mkdir -p /sdcard/Download
  cp "$CONFIG_FILE" /sdcard/GCam/Configs9/GCam_Config_sweet_k6a.xml 2>/dev/null || true
  cp "$CONFIG_FILE" /sdcard/GCam/Configs8/GCam_Config_sweet_k6a.xml 2>/dev/null || true
  cp "$CONFIG_FILE" /sdcard/Download/GCam_Config_sweet_k6a.xml 2>/dev/null || true
  cp "$CONFIG_FILE" /sdcard/Download/MGC.cfg 2>/dev/null || true

  # Direct preference injection if package directory exists
  PREFS_DIR="/data/data/com.google.android.GoogleCameraEng/shared_prefs"
  if [ -d "/data/data/com.google.android.GoogleCameraEng" ]; then
    mkdir -p "$PREFS_DIR"
    GCAM_UID=$(stat -c "%u" /data/data/com.google.android.GoogleCameraEng 2>/dev/null || echo "10000")
    cp "$CONFIG_FILE" "$PREFS_DIR/com.google.android.GoogleCameraEng_preferences.xml"
    chown -R "$GCAM_UID:$GCAM_UID" "$PREFS_DIR" 2>/dev/null || true
    chmod 660 "$PREFS_DIR/com.google.android.GoogleCameraEng_preferences.xml" 2>/dev/null || true
    restorecon -R /data/data/com.google.android.GoogleCameraEng 2>/dev/null || true
    ui_print "- Configuration applied directly to camera preferences!"
  fi
fi

# Register and install Google Camera APK in PackageManager if system is running
if [ "$(getprop sys.boot_completed)" = "1" ]; then
  ui_print "- Registering Google Camera APK in PackageManager..."
  pm install -r -d -g "$MODPATH/system/product/app/GoogleCameraEng/GoogleCameraEng.apk" >/dev/null 2>&1 || pm install -r "$MODPATH/system/product/app/GoogleCameraEng/GoogleCameraEng.apk" >/dev/null 2>&1 || true
fi

ui_print "- Google Camera System App installed successfully!"
ui_print "- Please reboot your device to apply system app mounts."
'''
with open(os.path.join(mod_dir, 'customize.sh'), 'w', newline='\n') as f:
    f.write(customize_content)

# 9. service.sh (Boot service)
service_content = '''#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 2
done

# Ensure Aperture remains suppressed
pm disable-user --user 0 org.lineageos.aperture >/dev/null 2>&1

# Ensure Google Camera APK is registered in PackageManager
if ! pm path com.google.android.GoogleCameraEng >/dev/null 2>&1; then
  APK_CAND=""
  if [ -f "$MODDIR/system/product/app/GoogleCameraEng/GoogleCameraEng.apk" ]; then
    APK_CAND="$MODDIR/system/product/app/GoogleCameraEng/GoogleCameraEng.apk"
  elif [ -f "$MODDIR/product/app/GoogleCameraEng/GoogleCameraEng.apk" ]; then
    APK_CAND="$MODDIR/product/app/GoogleCameraEng/GoogleCameraEng.apk"
  fi
  if [ -n "$APK_CAND" ]; then
    pm install -r -d -g "$APK_CAND" >/dev/null 2>&1 || pm install -r "$APK_CAND" >/dev/null 2>&1 || true
  fi
fi

# Ensure Google Camera has all required runtime permissions
pm grant com.google.android.GoogleCameraEng android.permission.CAMERA >/dev/null 2>&1
pm grant com.google.android.GoogleCameraEng android.permission.RECORD_AUDIO >/dev/null 2>&1
pm grant com.google.android.GoogleCameraEng android.permission.ACCESS_FINE_LOCATION >/dev/null 2>&1
pm grant com.google.android.GoogleCameraEng android.permission.ACCESS_COARSE_LOCATION >/dev/null 2>&1
pm grant com.google.android.GoogleCameraEng android.permission.READ_MEDIA_IMAGES >/dev/null 2>&1
pm grant com.google.android.GoogleCameraEng android.permission.READ_MEDIA_VIDEO >/dev/null 2>&1
pm grant com.google.android.GoogleCameraEng android.permission.READ_EXTERNAL_STORAGE >/dev/null 2>&1
pm grant com.google.android.GoogleCameraEng android.permission.WRITE_EXTERNAL_STORAGE >/dev/null 2>&1
appops set com.google.android.GoogleCameraEng MANAGE_EXTERNAL_STORAGE allow >/dev/null 2>&1
'''
with open(os.path.join(mod_dir, 'service.sh'), 'w', newline='\n') as f:
    f.write(service_content)

# 10. Create Flashable ZIP
zip_filename = os.path.join(base_dir, 'GCam_System_Module.zip')
if os.path.exists(zip_filename):
    os.remove(zip_filename)

print("Building flashable Magisk/KernelSU ZIP package...")
with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk(mod_dir):
        for file in files:
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, mod_dir)
            zipf.write(full_path, rel_path)

print(f'Google Camera KernelSU/Magisk Module created: {zip_filename} ({os.path.getsize(zip_filename)} bytes)')
