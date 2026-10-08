import os
import shutil
import zipfile

base_dir = os.path.dirname(os.path.abspath(__file__))
mod_dir = os.path.join(base_dir, 'System_Safe_Debloat_Module')
if os.path.exists(mod_dir):
    shutil.rmtree(mod_dir)

# 1. Directories
meta_dir = os.path.join(mod_dir, 'META-INF', 'com', 'google', 'android')
os.makedirs(meta_dir, exist_ok=True)

# OverlayFS directories to mask
replace_targets = [
    os.path.join(mod_dir, 'system', 'product', 'priv-app', 'SafetyHubPrebuilt'),
    os.path.join(mod_dir, 'system', 'product', 'priv-app', 'SafetyHub'),
    os.path.join(mod_dir, 'system', 'product', 'app', 'SafetyHubPrebuilt'),
    os.path.join(mod_dir, 'system', 'product', 'app', 'VoiceAccessPrebuilt'),
    os.path.join(mod_dir, 'system', 'product', 'priv-app', 'RecorderPrebuilt_847964105'),
    os.path.join(mod_dir, 'system', 'product', 'priv-app', 'RecorderPrebuilt'),
    os.path.join(mod_dir, 'system', 'system_ext', 'app', 'OmniJaws'),
]

for target in replace_targets:
    os.makedirs(target, exist_ok=True)
    with open(os.path.join(target, '.replace'), 'w') as f:
        pass

# 2. updater-script
with open(os.path.join(meta_dir, 'updater-script'), 'w', newline='\n') as f:
    f.write('#MAGISK\n')

# 3. update-binary
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

# 4. module.prop
module_prop_content = '''id=system_safe_debloat
name=System Safe Debloat
version=1.1
versionCode=110
author=Md Rony Hossen (rony1duet)
description=Systemlessly debloats bloatware apps for EvolutionX / AOSP / Pixel ROMs (Safety Hub, OmniJaws, VoiceAccess, Recorder) via overlayfs masking.
'''
with open(os.path.join(mod_dir, 'module.prop'), 'w', newline='\n') as f:
    f.write(module_prop_content)

# 5. customize.sh
customize_content = '''ui_print "**************************************************"
ui_print "       System Safe Debloat KernelSU Module        "
ui_print "       Maintained by Md Rony Hossen (rony1duet)   "
ui_print "**************************************************"

ui_print "- Disabling and uninstalling debloated packages..."
pm disable-user --user 0 com.google.android.apps.safetyhub >/dev/null 2>&1
pm uninstall -k --user 0 com.google.android.apps.safetyhub >/dev/null 2>&1
pm disable-user --user 0 com.google.android.apps.accessibility.voiceaccess >/dev/null 2>&1
pm uninstall -k --user 0 com.google.android.apps.accessibility.voiceaccess >/dev/null 2>&1
pm disable-user --user 0 com.google.android.apps.recorder >/dev/null 2>&1
pm uninstall -k --user 0 com.google.android.apps.recorder >/dev/null 2>&1
pm disable-user --user 0 org.omnirom.omnijaws >/dev/null 2>&1
pm uninstall -k --user 0 org.omnirom.omnijaws >/dev/null 2>&1

ui_print "- Setting module permissions..."
set_perm_recursive $MODPATH 0 0 0755 0644

ui_print "- System Safe Debloat installed successfully!"
ui_print "- Please reboot your device to apply full system mounts."
'''
with open(os.path.join(mod_dir, 'customize.sh'), 'w', newline='\n') as f:
    f.write(customize_content)

# 6. service.sh (Boot service)
service_content = '''#!/system/bin/sh
MODDIR=${0%/*}

# Wait for boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 2
done

# Ensure debloated apps remain suppressed across system updates
pm disable-user --user 0 com.google.android.apps.safetyhub >/dev/null 2>&1
pm disable-user --user 0 com.google.android.apps.accessibility.voiceaccess >/dev/null 2>&1
pm disable-user --user 0 com.google.android.apps.recorder >/dev/null 2>&1
pm disable-user --user 0 org.omnirom.omnijaws >/dev/null 2>&1
'''
with open(os.path.join(mod_dir, 'service.sh'), 'w', newline='\n') as f:
    f.write(service_content)

# 7. Create Flashable ZIP
zip_filename = os.path.join(base_dir, 'System_Safe_Debloat_Module.zip')
if os.path.exists(zip_filename):
    os.remove(zip_filename)

with zipfile.ZipFile(zip_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
    for root, dirs, files in os.walk(mod_dir):
        for file in files:
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, mod_dir)
            zipf.write(full_path, rel_path)

print(f'Magisk/KernelSU Debloat Module created: {zip_filename} ({os.path.getsize(zip_filename)} bytes)')
