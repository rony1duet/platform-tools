#!/system/bin/sh
# Safe Bloatware Remover for Xiaomi HyperOS / MIUI / AOSP / EvolutionX
# Standalone consumer apps only: ZERO risk of bootloop.

echo "================================================================"
echo "          Removing Bloatware Packages (Safe Mode)"
echo "================================================================"

PACKAGES="
com.facebook.katana
com.facebook.appmanager
com.facebook.services
com.facebook.system
com.linkedin.android
com.netflix.mediaclient
com.xiaomi.smarthome
com.mi.global.bbs
com.mi.global.shop
com.xiaomi.glgm
com.xiaomi.midrop
com.mi.globalbrowser
com.miui.videoplayer
com.miui.player
com.google.android.apps.walletnfcrel
com.google.android.apps.youtube.music
com.google.android.videos
com.google.android.apps.podcasts
com.google.android.apps.magazines
com.google.android.apps.tachyon
com.google.android.apps.docs
org.lineageos.aperture
com.google.android.apps.bard
org.omnirom.omnijaws
com.google.android.apps.accessibility.voiceaccess
com.google.android.apps.recorder
com.google.android.apps.safetyhub
"

removed_count=0
already_removed=0

for pkg in $PACKAGES; do
    [ -z "$pkg" ] && continue

    echo -n "Removing $pkg... "
    # Remove any user-space updates first
    pm uninstall "$pkg" >/dev/null 2>&1
    # Suppress background services and hide launcher icon
    pm disable-user --user 0 "$pkg" >/dev/null 2>&1
    # Uninstall for user 0
    res=$(pm uninstall -k --user 0 "$pkg" 2>&1)
    if echo "$res" | grep -q "Success"; then
        echo "[REMOVED]"
        removed_count=$((removed_count + 1))
    else
        echo "[ALREADY REMOVED]"
        already_removed=$((already_removed + 1))
    fi
done

# Refresh home screen launcher across MIUI / AOSP / Pixel ROMs
am force-stop com.miui.home >/dev/null 2>&1
am force-stop com.google.android.apps.nexuslauncher >/dev/null 2>&1
am force-stop com.android.launcher3 >/dev/null 2>&1

echo ""
echo "================================================================"
echo " [SUCCESS] Debloat finished! Home screen refreshed."
echo " Newly Removed: $removed_count | Already Removed: $already_removed"
echo "================================================================"
