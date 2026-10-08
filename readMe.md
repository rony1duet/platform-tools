# Android Safe Debloater, KernelSU & Google Camera Tool

A reliable, bootloop-proof debloater, KernelSU installer, and Google Camera system-app toolkit for Xiaomi HyperOS / MIUI and AOSP / EvolutionX / LineageOS devices.

[![Build Modules](https://github.com/rony1duet/platform-tools/actions/workflows/build-modules.yml/badge.svg)](https://github.com/rony1duet/platform-tools/actions/workflows/build-modules.yml)
[![GitHub release](https://img.shields.io/github/v/release/rony1duet/platform-tools?include_prereleases&label=Latest%20Release)](https://github.com/rony1duet/platform-tools/releases)

---

## Directory Structure

```text
platform-tools/
├── autoDebloatAndSetup.bat       # Master one-click launcher (Windows)
├── LunarisDolby_Magisk_Module.zip # Flashable Magisk/KernelSU Dolby Atmos module
├── create_module.py              # Generator script for Dolby Atmos module
├── System_Safe_Debloat_Module.zip # Flashable Magisk/KernelSU Safe Debloat module
├── create_debloat_module.py      # Generator script for Safe Debloat module
├── GCam_System_Module.zip        # Flashable Magisk/KernelSU Google Camera module
├── create_gcam_module.py         # Generator script for Google Camera module
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
│   ├── KernelSU_Next_v3.4.0_33294-release.apk
│   ├── LunarisDolby.apk          # Rebuilt Lunaris Dolby Atmos APK (rony1duet credit)
│   ├── GCam_Config_sweet_k6a.xml # XML configuration for Redmi Note 10 Pro (sweet)
│   └── (MGC_9.6.xxx APK downloaded dynamically by script into apk/)
│
├── LunarisDolby/                 # Lunaris Dolby Atmos source code repo
│   └── src/org/lunaris/dolby/ui/components/CreditsDialog.kt
│
└── scripts/                      # Native Android shell & Python scripts
    ├── debloatSu.sh
    ├── restoreSu.sh
    ├── setupDebloatModule.sh
    ├── setupGcamModule.sh
    └── download_gcam.py          # Auto-scraper & downloader for latest BSG MGC 9.6xx APK
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

 [1] FULL AUTOMATION (Install KernelSU + Safe Debloat + GCam)
 [2] Run Safe Debloat Script (Package Uninstaller)
 [3] Install KernelSU Safe Debloat Module (Systemless OverlayFS)
 [4] Setup Google Camera (MGC) System App (Only GCam Install & Camera Removal)
 [5] Install / Reinstall KernelSU Next Manager APK
 [6] Restore Debloated Apps
 [7] Check Device & Root Status
 [8] Download / Update Google Camera (BSG MGC 9.6xx)
 [0] Exit
```

---

## File Overview

| Path | Description |
| :--- | :--- |
| **`autoDebloatAndSetup.bat`** | **Master one-click automation tool for Windows.** Automatically locates `adb/`, `apk/`, and `scripts/`, checks root, runs installs, debloats, automatically downloads the latest BSG MGC 9.6xx APK if missing, and refreshes the launcher. |
| **`create_debloat_module.py`** | Python generator that packages the flashable `System_Safe_Debloat_Module.zip` KernelSU/Magisk debloat module with overlayfs masks and boot persistence. |
| **`System_Safe_Debloat_Module.zip`** | Flashable KernelSU/Magisk module that systemlessly masks out bloatware (Safety Hub, OmniJaws, VoiceAccess, Recorder). |
| **`create_gcam_module.py`** | Python generator that automatically ensures the latest MGC 9.6xx APK is present and compiles `GCam_System_Module.zip` with 64-bit native libraries, sweet k6a configuration, and Aperture masking. |
| **`GCam_System_Module.zip`** | Flashable KernelSU/Magisk module that installs Google Camera (MGC 9.6.080) as a system app and imports tuned preferences. |
| **`create_module.py`** | Python generator that packages the flashable `LunarisDolby_Magisk_Module.zip` with permissions, configs, and platform overlays. |
| **`LunarisDolby_Magisk_Module.zip`** | Flashable Magisk/KernelSU module containing modern Compose Material 3 Lunaris Dolby Atmos. |
| **`scripts/download_gcam.py`** | Standalone tool that queries BSG's portal on Celso Azevedo, detects the latest MGC 9.6xx release, and automatically downloads the verified `_ENG.apk` package with download progress. |
| **`scripts/debloatSu.sh`** | Native Android root shell script targeting standalone bloatware (Facebook suite, LinkedIn, Netflix, Mi Home, Google consumer apps, Aperture, Bard, OmniJaws, VoiceAccess, Recorder, Safety Hub). |
| **`scripts/restoreSu.sh`** | Native Android root shell script that re-installs and re-enables debloated packages. |
| **`scripts/setupDebloatModule.sh`** | Native Android root shell script that creates a KernelSU systemless module to mask unwanted system apps via overlayfs. |
| **`scripts/setupGcamModule.sh`** | Native Android root shell script that builds the KernelSU systemless module for Google Camera (MGC 9.6.080), extracts 64-bit native libraries, and replaces the stock Aperture camera. |
| **`apk/`** | Contains official APKs for KernelSU Next Manager v3.4.0, Lunaris Dolby Atmos, and device configs. (Large MGC GCam APKs are ignored in Git and downloaded dynamically on demand). |
| **`adb/`** | Official Google Android SDK platform tools binaries and Windows drivers. |
| **`appList.txt`** | Reference list of known package names across Android distributions. |
| **`readMe.md`** | Project documentation and usage guide. |

---

## Bootloop Safety Guarantee

* **Strict Dependency Safety**: Only standalone and user-space consumer bloatware is targeted. SystemUI, Keyguard, and critical framework services are strictly protected.
* **KernelSU Systemless Mount**: System partition alterations (such as replacing Aperture with Google Camera) are performed safely via KernelSU overlay modules in `/data/adb/modules/`, leaving read-only dm-verity partitions unmodified.
* Your device can be rebooted safely at any time with ZERO risk of entering Recovery Mode.
