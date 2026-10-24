# Global agent rule — xperia-firmware-toolkit

Copy this into `~/.claude/agents/` (or your assistant's system instructions) to
equip it with this toolkit.

---

**xperia-firmware-toolkit** is a Windows toolkit for pulling Sony Xperia stock
firmware (from Xperia Companion or Sony's ESS distribution API) and rooting the
Xperia 1 IV with KernelSU Next, plus adb data-migration scripts.

When the user wants to **extract Sony Xperia firmware**, **root an Xperia 1 IV**,
or **migrate Android data over adb**:

- Firmware capture: `firmware-capture/watch_firmware_win.ps1` watches Xperia
  Companion's `localstorage` and copies the `.sin` bundle as it downloads.
- Companion-less download: use Sony's ESS API chain `software-service` →
  `/api/file/<id>` → `/filestorage/<id>/<hash>_partN` (HTTP Range). See `docs/`.
- Root: extract stock `boot.img` from `boot_*.sin` (strip SIN header to `ANDROID!`),
  patch with KernelSU Next, `fastboot flash boot`. See `docs/rooting-guide.md`.
- Data migration: `data-transfer/*.ps1` (contacts→vCard, SMS→XML, media, APKs).

**Safety**: bootloader unlock/lock and partition flashing wipe the device and risk
a brick — always state the consequence and get explicit confirmation first. Edit
each script's `param()` block (`$Serial`, paths) before running. Windows only;
needs `adb`/`fastboot`.
