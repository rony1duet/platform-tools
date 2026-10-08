import os
import shutil
import zipfile

base_dir = os.path.dirname(os.path.abspath(__file__))
mod_dir = os.path.join(base_dir, 'LunarisDolby_Magisk_Module')
if os.path.exists(mod_dir):
    shutil.rmtree(mod_dir)

# 1. Directories
meta_dir = os.path.join(mod_dir, 'META-INF', 'com', 'google', 'android')
os.makedirs(meta_dir, exist_ok=True)

sys_app_dir = os.path.join(mod_dir, 'system', 'system_ext', 'priv-app', 'LunarisDolby')
os.makedirs(sys_app_dir, exist_ok=True)

sys_perm_dir = os.path.join(mod_dir, 'system', 'system_ext', 'etc', 'permissions')
os.makedirs(sys_perm_dir, exist_ok=True)

sys_sysconfig_dir = os.path.join(mod_dir, 'system', 'system_ext', 'etc', 'sysconfig')
os.makedirs(sys_sysconfig_dir, exist_ok=True)

prod_overlay_dir = os.path.join(mod_dir, 'system', 'product', 'overlay')
os.makedirs(prod_overlay_dir, exist_ok=True)

vendor_dolby_dir = os.path.join(mod_dir, 'system', 'vendor', 'etc', 'dolby')
os.makedirs(vendor_dolby_dir, exist_ok=True)

vendor_etc_dir = os.path.join(mod_dir, 'system', 'vendor', 'etc')
os.makedirs(vendor_etc_dir, exist_ok=True)

vendor_vintf_dir = os.path.join(mod_dir, 'system', 'vendor', 'etc', 'vintf', 'manifest')
os.makedirs(vendor_vintf_dir, exist_ok=True)

common_dir = os.path.join(mod_dir, 'common')
os.makedirs(common_dir, exist_ok=True)

# 2. Copy compiled APK to system priv-app and common
src_apk = os.path.join(base_dir, 'apk', 'LunarisDolby.apk')
shutil.copy2(src_apk, os.path.join(sys_app_dir, 'LunarisDolby.apk'))
shutil.copy2(src_apk, os.path.join(common_dir, 'LunarisDolby.apk'))

# Mask old stock DolbyManager app directory with .replace
old_dolby_dir = os.path.join(mod_dir, 'system', 'system_ext', 'priv-app', 'DolbyManager')
os.makedirs(old_dolby_dir, exist_ok=True)
with open(os.path.join(old_dolby_dir, '.replace'), 'w') as f:
    pass

# 3. Copy permissions and sysconfig
shutil.copy2(os.path.join(base_dir, 'dolby_dump', 'permissions', 'privapp-permissions-dolby.xml'), os.path.join(sys_perm_dir, 'privapp-permissions-dolby.xml'))
shutil.copy2(os.path.join(base_dir, 'dolby_dump', 'permissions', 'preinstalled-packages-platform-dolby.xml'), os.path.join(sys_sysconfig_dir, 'preinstalled-packages-platform-dolby.xml'))

# 4. Copy overlay
shutil.copy2(os.path.join(base_dir, 'dolby_dump', 'overlay', 'DolbyFrameworksResCommon.apk'), os.path.join(prod_overlay_dir, 'DolbyFrameworksResCommon.apk'))

# 5. Copy vendor configs
shutil.copy2(os.path.join(base_dir, 'dolby_dump', 'vendor_etc', 'dax-default.xml'), os.path.join(vendor_dolby_dir, 'dax-default.xml'))
shutil.copy2(os.path.join(base_dir, 'dolby_dump', 'vendor_etc', 'media_codecs_dolby_audio.xml'), os.path.join(vendor_etc_dir, 'media_codecs_dolby_audio.xml'))
shutil.copy2(os.path.join(base_dir, 'dolby_dump', 'vendor_etc', 'vendor.dolby.hardware.dms@2.0-service.xml'), os.path.join(vendor_vintf_dir, 'vendor.dolby.hardware.dms@2.0-service.xml'))
shutil.copy2(os.path.join(base_dir, 'dolby_dump', 'vendor_etc', 'vendor.dolby.media.c2.xml'), os.path.join(vendor_vintf_dir, 'vendor.dolby.media.c2.xml'))

# 5.5 Replace old overlay
old_overlay_dir = os.path.join(mod_dir, 'system', 'product', 'overlay', 'DolbyManager__custom_sweet2__auto_generated_rro_product')
os.makedirs(old_overlay_dir, exist_ok=True)
with open(os.path.join(old_overlay_dir, '.replace'), 'w') as f:
    pass

# 6. updater-script
with open(os.path.join(meta_dir, 'updater-script'), 'w', newline='\n') as f:
    f.write('#MAGISK\n')

# 7. update-binary
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

# 8. module.prop
module_prop_content = '''id=lunaris_dolby_atmos
name=Lunaris Dolby Atmos
version=1.0
versionCode=100
author=MD RONY HOSSEN (rony1duet)
description=Lunaris Dolby Atmos with modern Compose Material 3 UI for AOSP custom ROMs. Replaces stock co.aospa.dolby. Maintained by rony1duet.
'''
with open(os.path.join(mod_dir, 'module.prop'), 'w', newline='\n') as f:
    f.write(module_prop_content)

# 9. customize.sh
customize_content = '''ui_print "**************************************************"
ui_print "           Lunaris Dolby Atmos Module             "
ui_print "       Maintained by MD RONY HOSSEN (rony1duet)   "
ui_print "**************************************************"

ui_print "- Disabling stock co.aospa.dolby..."
pm disable-user --user 0 co.aospa.dolby >/dev/null 2>&1 || true
pm uninstall -k --user 0 co.aospa.dolby >/dev/null 2>&1 || true
pm disable-user --user 0 co.aospa.dolby.auto_generated_rro_product__ >/dev/null 2>&1 || true
pm uninstall -k --user 0 co.aospa.dolby.auto_generated_rro_product__ >/dev/null 2>&1 || true

ui_print "- Masking stock DolbyManager app & overlay..."
mkdir -p $MODPATH/system/system_ext/priv-app/DolbyManager
touch $MODPATH/system/system_ext/priv-app/DolbyManager/.replace
mkdir -p $MODPATH/system/product/overlay/DolbyManager__custom_sweet2__auto_generated_rro_product
touch $MODPATH/system/product/overlay/DolbyManager__custom_sweet2__auto_generated_rro_product/.replace

ui_print "- Setting module file permissions..."
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/system/system_ext/priv-app/LunarisDolby/LunarisDolby.apk 0 0 0644
set_perm $MODPATH/system/product/overlay/DolbyFrameworksResCommon.apk 0 0 0644

# Register and install Lunaris Dolby Atmos in PackageManager if system is running
APK_CAND=""
for cand in "$MODPATH/system/system_ext/priv-app/LunarisDolby/LunarisDolby.apk" "$MODPATH/system_ext/priv-app/LunarisDolby/LunarisDolby.apk" "$MODPATH/common/LunarisDolby.apk"; do
  if [ -f "$cand" ]; then
    APK_CAND="$cand"
    break
  fi
done

if [ -n "$APK_CAND" ]; then
  if [ "$(getprop sys.boot_completed)" = "1" ] || (command -v pm >/dev/null 2>&1 && pm path android >/dev/null 2>&1); then
    ui_print "- Registering Lunaris Dolby Atmos APK in PackageManager..."
    pm install -r -d -g "$APK_CAND" >/dev/null 2>&1 || pm install -r "$APK_CAND" >/dev/null 2>&1 || true
    pm grant org.lunaris.dolby android.permission.MODIFY_AUDIO_ROUTING >/dev/null 2>&1 || true
    pm grant org.lunaris.dolby android.permission.RECORD_AUDIO >/dev/null 2>&1 || true
    appops set org.lunaris.dolby GET_USAGE_STATS allow >/dev/null 2>&1 || true
    ui_print "- Lunaris Dolby Atmos APK installed and permissions granted!"
  else
    ui_print "- Note: APK staged and will be finalized on next boot by service.sh"
  fi
fi

ui_print "- Verifying installation..."
if [ -f $MODPATH/system/system_ext/priv-app/LunarisDolby/LunarisDolby.apk ]; then
  ui_print "- LunarisDolby APK staged successfully in module!"
fi

ui_print "- Installation complete! Please reboot your device to apply system audio mounts."
'''
with open(os.path.join(mod_dir, 'customize.sh'), 'w', newline='\n') as f:
    f.write(customize_content)

# 9.5 service.sh (Boot service)
service_content = '''#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 2
done

# Ensure stock co.aospa.dolby remains suppressed
pm disable-user --user 0 co.aospa.dolby >/dev/null 2>&1 || true
pm disable-user --user 0 co.aospa.dolby.auto_generated_rro_product__ >/dev/null 2>&1 || true

# Install LunarisDolby APK if missing (e.g. flashed in recovery or uninstalled)
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
'''
with open(os.path.join(mod_dir, 'service.sh'), 'w', newline='\n') as f:
    f.write(service_content)

# 10. Create Flashable ZIP
zip_filename = os.path.join(base_dir, 'LunarisDolby_Magisk_Module.zip')
if os.path.exists(zip_filename):
    os.remove(zip_filename)

with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk(mod_dir):
        for file in files:
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, mod_dir)
            zipf.write(full_path, rel_path)

print(f'Magisk/KernelSU Module package created: {zip_filename} ({os.path.getsize(zip_filename)} bytes)')
