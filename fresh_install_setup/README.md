# Redmi Note 12 Pro (`sweet2` / `sweet_k6a`) Fresh Setup Bundle

This turnkey bundle contains all automated scripts and binary prebuilts needed to completely configure your device after a factory reset or clean ROM flash.

## Included Components

1. **LunarisDolby (`co.aospa.dolby`)**:
   - Recompiled with standard AOSP platform keys (`CN=Android, OU=Android`).
   - Integrated into `/system_ext/priv-app/DolbyManager/` with `privapp-permissions-dolby.xml`.
   - Single launcher icon (duplicate alias removed).
   - Dynamic summary tile in **Settings → Sound & vibration → Dolby Atmos**.

2. **System Debloat**:
   - Partition-level debloat: removes `Aperture` (7.9 MB), `SafetyHubPrebuilt` (29 MB), `FM2` (1.4 MB), `ShinkaiWalls` (7.6 MB), `MagicPortraitWallpapers` (54 MB), `Stk` (3.8 MB), and `DocumentsUIGoogle` (10 MB).
   - Package manager uninstall for user 0 (`pm uninstall -k --user 0`).

3. **GCam V52 & Config**:
   - `MGC_9.6.080_V52_ENG.apk` cleanly installed.
   - `BSG_9.6_Pixel_8_v260423.xml` staged in `/sdcard/GCam/Configs9/` and `/sdcard/Download/`.
   - All runtime permissions granted (Camera, Audio, Fine/Coarse Location, Media, Storage).

4. **Device Properties Correction**:
   - Replaces `Pixel 11 Pro XL` with `Redmi Note 12 Pro`.
   - Replaces `kodiak` / `kodiak_beta` with `sweet2`.
   - Sets brand to `Redmi` and manufacturer to `Xiaomi`.
   - Patches all 5 partition `build.prop` files (`/system`, `/system_ext`, `/product`, `/vendor`, `/odm`).
   - Installs boot script `/data/adb/post-fs-data.d/01_device_props.sh` using KernelSU's `resetprop` for persistence.

5. **Lockscreen Auto-Rotate Button Fix**:
   - Disables floating rotate suggestion button via `settings put secure show_rotation_suggestions 0`.

---

## How to Run After Factory Reset

1. Complete initial Android setup wizard.
2. Enable **USB Debugging** in Developer options.
3. Open **KernelSU Next** and grant Root permissions to Shell / ADB (or keep ADB root active).
4. Run:
   - **Double-click**: `apply_fresh_setup.bat`  
   *or*
   - **PowerShell**:
     ```powershell
     & "d:\Github\platform-tools\fresh_install_setup\apply_fresh_setup.ps1"
     ```
5. Done! The script automatically applies all changes, resizes partitions, and restarts zygote.
