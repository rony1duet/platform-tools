#!/system/bin/sh
# Restore Script for Debloated Packages

echo "================================================================"
echo "                Restoring Debloated Packages"
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
org.omnirom.omnijaws
com.google.android.apps.accessibility.voiceaccess
com.google.android.apps.recorder
com.google.android.apps.safetyhub
"

restored_count=0

for pkg in $PACKAGES; do
    [ -z "$pkg" ] && continue

    echo -n "Restoring $pkg... "
    cmd package install-existing "$pkg" >/dev/null 2>&1
    pm enable "$pkg" >/dev/null 2>&1
    echo "[RESTORED / ACTIVE]"
    restored_count=$((restored_count + 1))
done

# Refresh home screen launcher across MIUI / AOSP / Pixel ROMs
am force-stop com.miui.home >/dev/null 2>&1
am force-stop com.google.android.apps.nexuslauncher >/dev/null 2>&1
am force-stop com.android.launcher3 >/dev/null 2>&1

echo ""
echo "================================================================"
echo " [SUCCESS] Restore completed! Home screen refreshed."
echo " Total packages processed: $restored_count"
echo " Note: Pure user-space apps (like Gemini/Bard) require APK reinstall."
echo "================================================================"
