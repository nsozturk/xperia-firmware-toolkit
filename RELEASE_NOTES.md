# v1.0.0 — Initial release

First public release of **xperia-firmware-toolkit** — a free, open-source Windows
toolkit for pulling Sony Xperia stock firmware (from Xperia Companion or Sony's ESS
distribution API) and rooting the Xperia 1 IV (XQ-CT72 / PDX223) with KernelSU Next.

## Highlights

- **Firmware capture** — `watch_firmware_win.ps1` grabs the firmware Xperia Companion
  downloads on Windows (`localstorage\<REGION>\FILE_<id>`, a ZIP of partition `.sin` files).
- **Companion-less download** — call Sony's public ESS distribution API directly
  (`software-service` → `/api/file` → `/filestorage`, HTTP Range). No MITM, no pinning bypass.
- **Reverse-engineering notes** — Companion's Java/OSGi internals, the JRE-truststore
  MITM method, metadata files, and the Sony `.sin` format.
- **Rooting guide** — extract stock `boot.img`, patch with KernelSU Next, `fastboot
  flash boot`, then Zygisk + PlayIntegrityFix/Fork + TrickyStore.
- **adb data migration** — contacts → vCard, SMS → restorable XML, media push, APK
  extraction and Play-Store-vs-sideload classification.
- **Bundled tools** — KernelSU Next, Magisk, APatch, ZygiskNext, Shamiko, TrickyStore,
  PlayIntegrityFix/Fork, AdAway, AlwaysTrustUserCerts, TrustMeAlready, JustTrustMe and
  Frida unpinning scripts (see `tools/CREDITS.md` for upstream + licenses).
- **Docs site** at https://nsozturk.github.io/xperia-firmware-toolkit/

## Notes

- Windows 10/11; needs Android platform-tools (`adb`/`fastboot`). PowerShell + Python.
- For your own devices / security research. Bootloader unlock wipes the device and
  revokes DRM keys. No Sony firmware is redistributed.
