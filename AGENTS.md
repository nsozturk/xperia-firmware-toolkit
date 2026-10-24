# AGENTS.md — xperia-firmware-toolkit

Contract for coding agents (Claude Code, Cursor, Gemini CLI, Codex, Antigravity)
operating this repository. Human-readable; every command is non-interactive.

## What this repo is
A Windows toolkit + research for pulling Sony Xperia stock firmware (via Xperia
Companion or Sony's ESS distribution API) and rooting the Xperia 1 IV, plus
adb-based Android data-migration scripts. PowerShell + Python. No build step.

## Operational truths
- **Platform**: Windows 10/11. Scripts are PowerShell `.ps1`; one mitmproxy addon is Python.
- **Prerequisites**: Android platform-tools (`adb`, `fastboot`) on PATH. For firmware
  work, Xperia Companion installed. For fastboot on Windows, a WinUSB driver (Zadig).
- **Per-script config**: edit the `param(...)` block at the top of each `.ps1`
  (`$Serial`, `$Sony`, paths) before running. Target a device by serial when two are attached.
- **Nothing here is destructive by itself** except the documented `fastboot oem unlock`
  / `fastboot flash` / `fastboot oem lock` steps in `docs/rooting-guide.md`, which
  **wipe the device**. Never run those without explicit user confirmation.

## Common commands
```powershell
# Capture firmware while Xperia Companion downloads it (run before/at flash start)
powershell -ExecutionPolicy Bypass -File firmware-capture\watch_firmware_win.ps1

# adb migration (source phone, USB debugging on)
powershell -ExecutionPolicy Bypass -File data-transfer\contacts_to_vcf.ps1     # contacts -> .vcf
powershell -ExecutionPolicy Bypass -File data-transfer\sms_to_xml.ps1          # SMS -> restorable XML
powershell -ExecutionPolicy Bypass -File data-transfer\pull_apks.ps1           # extract APKs
powershell -ExecutionPolicy Bypass -File data-transfer\check_playstore.ps1     # Play Store vs sideload
powershell -ExecutionPolicy Bypass -File data-transfer\push_media_to_sony.ps1  # push media to target
powershell -ExecutionPolicy Bypass -File data-transfer\install_apks_to_sony.ps1 # install APKs to target
```

## adb/fastboot quick reference
```bash
adb devices -l                 # list; grab the serial
adb -s <serial> shell ...      # target a specific device
adb reboot bootloader          # enter fastboot
fastboot devices               # verify fastboot sees it (needs WinUSB driver)
fastboot flash boot <img>      # flash a boot image to the active slot
```

## Failure fallbacks
- **`adb` daemon slow/hangs on first run**: antivirus scanning the fresh binary; wait, retry.
- **`fastboot devices` empty**: install WinUSB for the Sony fastboot interface with Zadig.
- **`fastboot flash boot` → "Volume Full"**: the image is larger than the partition;
  trim trailing zero padding to the exact partition size, then reflash.
- **Companion "Driver for software update is missing"**: run Companion as admin;
  reinstall the SWUP driver via `DriverInstaller64.exe`.

## Safety gate
Treat bootloader unlock/lock and partition flashing as irreversible. State the
consequence (wipe, DRM loss, brick risk) and get explicit user confirmation first.
