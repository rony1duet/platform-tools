# Android Safe Debloater, KernelSU & Google Camera Tool

A reliable, bootloop-proof debloater, KernelSU installer, and Google Camera system-app toolkit for Xiaomi HyperOS / MIUI and AOSP / EvolutionX / LineageOS devices.

---

## Directory Structure

```text
platform-tools/
├── autoDebloatAndSetup.bat       # Master one-click launcher (Windows)
├── LunarisDolby_Magisk_Module.zip # Flashable Magisk/KernelSU module
├── create_module.py              # Generator script for Magisk/KernelSU module
├── appList.txt                   # Reference package catalog
├── readMe.md                     # Project documentation
│
├── adb/                          # Android SDK platform tools
│   ├── adb.exe
│   ├── AdbWinApi.dll
│   ├── AdbWinUsbApi.dll
│   ├── fastboot.exe
│   └── ...
│
├── apk/                          # Android application packages
│   ├── KernelSU_Next_v3.3.0_33214-release.apk
│   ├── LunarisDolby.apk          # Rebuilt Lunaris Dolby Atmos APK (rony1duet credit)
│   └── MGC_9.6.080_V51_ENG.apk
│
├── LunarisDolby/                 # Lunaris Dolby Atmos source code repo
│   └── src/org/lunaris/dolby/ui/components/CreditsDialog.kt
│
└── scripts/                      # Native Android shell scripts
    ├── debloatSu.sh
    ├── restoreSu.sh
    └── setupGcamModule.sh
```

---

## Quick Start

1. Connect your phone via USB with **USB Debugging** enabled in Developer Options.
2. Double-click **`autoDebloatAndSetup.bat`** in Windows File Explorer.
3. Choose your option from the interactive menu:

```text
================================================================
      ANDROID SAFE DEBLOATER & KERNELSU SETUP TOOL
================================================================

 [1] FULL AUTOMATION (Install KernelSU + Run Safe Debloat)
 [2] Run Safe Debloat Only (Includes Aperture, Bard, OmniJaws, etc.)
 [3] Install / Reinstall KernelSU Next Manager APK
 [4] Setup Google Camera (MGC) as System App (Replace Aperture)
 [5] Restore Debloated Apps
 [6] Check Device & Root Status
 [0] Exit
```

---

## File Overview

| Path | Description |
| :--- | :--- |
| **`autoDebloatAndSetup.bat`** | **Master one-click automation tool for Windows.** Automatically locates `adb/`, `apk/`, and `scripts/`, checks root, runs installs, debloats, and refreshes the launcher. |
| **`scripts/debloatSu.sh`** | Native Android root shell script targeting standalone bloatware (Facebook suite, LinkedIn, Netflix, Mi Home, Google consumer apps, Aperture, Bard, OmniJaws, VoiceAccess, Recorder). |
| **`scripts/restoreSu.sh`** | Native Android root shell script that re-installs and re-enables debloated packages. |
| **`scripts/setupGcamModule.sh`** | Native Android root shell script that builds the KernelSU systemless module for Google Camera (MGC 9.6.080), extracts 64-bit native libraries, and masks Aperture, OmniJaws, VoiceAccess, and Recorder. |
| **`apk/`** | Contains official APKs for KernelSU Next Manager and Google Camera (MGC 9.6.080 V51 ENG). |
| **`adb/`** | Official Google Android SDK platform tools binaries and Windows drivers. |
| **`appList.txt`** | Reference list of known package names across Android distributions. |
| **`readMe.md`** | Project documentation and usage guide. |

---

## Bootloop Safety Guarantee

* **Strict Dependency Safety**: Only standalone and user-space consumer bloatware is targeted. SystemUI, Keyguard, and critical framework services are strictly protected.
* **KernelSU Systemless Mount**: System partition alterations (such as replacing Aperture with Google Camera) are performed safely via KernelSU overlay modules in `/data/adb/modules/`, leaving read-only dm-verity partitions unmodified.
* Your device can be rebooted safely at any time with ZERO risk of entering Recovery Mode.
