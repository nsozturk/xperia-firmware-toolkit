# Rooting the Xperia 1 IV (XQ-CT72 / PDX223) — Android 14

Complete walkthrough to root a Sony Xperia 1 IV from scratch, including the hard
part (getting Sony firmware), start to finish.

> **Device:** XQ-CT72 (SEA / dual-SIM) · **Platform:** PDX223 · **SoC:** SM8450 (SD 8 Gen 1)
> **Android:** 14 · **Example build:** 64.2.A.2.265 · **Kernel:** GKI 2.0 (5.10)

---

## ⚠️ Read first

- **Unlocking the bootloader wipes the device completely** (factory reset) and
  **permanently revokes Sony DRM keys** (some camera/display features may change).
- Flashing the wrong `boot.img` causes a **bootloop** — the boot image must match
  your **exact firmware build**. If your build differs, extract the boot image from
  **your** firmware (see Part 1).
- Everything here is for **your own device / security research**.

## What you need

The tools used below are bundled under [`tools/`](../tools/) with upstream credits
in [`tools/CREDITS.md`](../tools/CREDITS.md):

| Tool | Purpose |
|------|---------|
| `tools/root/KernelSU_Next-*.apk` | **Primary** root method |
| `tools/root/Magisk-*.apk` | Alternative |
| `tools/root/APatch-*.apk` | Alternative |
| `tools/root/ZygiskNext-*.zip`, `Shamiko-*.zip`, `TrickyStoreOSS-*.zip`, `PlayIntegrityFork-*.zip` | Zygisk + Play Integrity chain |

Plus: Android platform-tools (`adb`/`fastboot`), a Sony **bootloader unlock code**
(from Sony Open Devices, tied to your IMEI), and a stock `boot.img` for your build.

---

## Part 0 — Get the stock firmware

Sony does not publish firmware directly. Two routes:

- **Capture from Xperia Companion** — run a "Software repair"; the firmware lands in
  `%LOCALAPPDATA%\Sony\Xperia Companion\<InstallTime>\localstorage\<REGION>\` as
  `FILE_<contentId>` (a ZIP of all partition `.sin` files). See
  [xperia-companion-firmware-capture.md](xperia-companion-firmware-capture.md) and
  the watcher `firmware-capture/watch_firmware_win.ps1`.
- **Sony ESS API** — download it without Companion. See
  [sony-ess-api-direct-download.md](sony-ess-api-direct-download.md).

---

## Part 1 — Extract the stock boot.img (.sin → .img)

The firmware ZIP contains `boot_X-FLASH-ALL-XXXX.sin` (Sony SIN format, not a raw
image). Strip the SIN header up to the `ANDROID!` magic (3584 bytes on the analysed
build); the remainder is a valid boot image. Verify: it must start with `ANDROID!`
and report `header_version 4`.

---

## Part 2 — Unlock the bootloader (WIPES THE DEVICE)

1. Get your code at `developer.sony.com/open-devices/unlock-bootloader` (enter IMEI,
   `*#06#`).
2. Power off → hold **Volume Up** and plug in USB → **blue LED** = fastboot mode.
3. On Windows the Sony fastboot interface needs a **WinUSB driver** — install it with
   [Zadig](https://zadig.akeo.ie) (List All Devices → select the `0FCE 0DDE` device →
   WinUSB → Replace Driver).
4. ```bash
   fastboot devices
   fastboot oem unlock 0x<YOUR_UNLOCK_CODE>
   ```
5. The device wipes and reboots. Finish setup, then re-enable **USB debugging** and
   keep **OEM unlocking** on.

---

## Part 3A — Root with KernelSU Next (primary)

GKI device → **LKM mode** (the app patches the stock boot image):

1. Install `tools/root/KernelSU_Next-*.apk`.
2. Copy your stock `boot.img` to the phone.
3. KernelSU Next app → **Install → Select and Patch a File** → pick the boot image →
   output: `kernelsu_next_patched_*.img` (in Download).
4. ```bash
   fastboot flash boot kernelsu_next_patched.img
   fastboot reboot
   ```
   > If `fastboot flash boot` fails with "Volume Full", the image is 1 KB larger than
   > the partition — trim trailing zero padding to the exact partition size and reflash.
5. The KernelSU Next app should show **Working / <version>**.

## Part 3B — Root with Magisk (alternative)

1. Install `tools/root/Magisk-*.apk`.
2. Magisk → **Install → Select and Patch a File** → stock `boot.img` → `magisk_patched_*.img`.
3. `fastboot flash boot magisk_patched.img && fastboot reboot`.
4. Enable **Zygisk** and **Enforce DenyList** (or use Shamiko).

---

## Part 4 — Zygisk + Play Integrity chain

After root (Magisk's built-in Zygisk, or ZygiskNext on KernelSU/APatch):

1. **Enable Zygisk** — Magisk: built-in; KernelSU Next / APatch: install
   `tools/root/ZygiskNext-*.zip`.
2. **Shamiko** (`tools/root/Shamiko-*.zip`) — root hiding (set DenyList to whitelist mode).
   Note: Shamiko is incompatible with some KernelSU Next versions; KernelSU Next's own
   "umount modules" hiding can be used instead.
3. **TrickyStore** (`tools/root/TrickyStoreOSS-*.zip`) — keystore attestation. Put a
   valid `keybox.xml` in `/data/adb/tricky_store/` and set `target.txt`.
4. **PlayIntegrityFork** (`tools/root/PlayIntegrityFork-*.zip`) — device fingerprint.
   Run its action (`autopif`) online for a fresh fingerprint.
5. Clear Google Play Services / Play Store data, reboot, and test Play Integrity.

---

## Quick reference

```bash
adb devices                       # device connected + debugging
adb reboot bootloader             # enter fastboot (or Vol-Up + USB)
fastboot devices
fastboot getvar unlocked          # is the bootloader unlocked
fastboot flash boot <patched>.img
fastboot reboot
```

## Troubleshooting
- **Bootloop:** wrong/mismatched boot.img — reflash the stock boot and verify the build.
- **Companion "driver missing":** run Companion as admin; if the SOMC flash driver is
  broken, reinstall it with `Program Files\Sony\SWUP-drivers\DriverInstaller64.exe`.
- **`fastboot` sees no device:** install the WinUSB driver with Zadig; try another USB port.
- **Re-locking:** NEVER `fastboot oem lock` while rooted/modified — it bricks. Restore
  100% stock first (stock boot + a full Companion repair), verify it boots, then lock.
