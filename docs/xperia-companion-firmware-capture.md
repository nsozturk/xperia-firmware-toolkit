# Capturing firmware from Xperia Companion (Windows)

Where Sony's **Xperia Companion** stores firmware on Windows, and how to grab it.
Observed on Companion **26.7.1**.

> For research on your own device. No Sony firmware is redistributed here.

## Where firmware lands (confirmed)

Companion install / data root:
`%LOCALAPPDATA%\Sony\Xperia Companion\`

- Static: `jre\`, `plugins\`, `configuration\`, `licenses\`, `setup\`
- Per-install data dir (timestamped, e.g. `2026-10-21-150253`):
  - `log\` → Sony-encrypted binary log (not plain text)
  - `temp\`, `workspace\` → firmware does **not** land here
  - **`localstorage\<REGION>\` (e.g. `localstorage\US\`) → FIRMWARE LANDS HERE**

### Download mechanics
1. First as **100 MB chunks** named `FILE_<contentId>_part0 … _partN`.
2. On completion Companion **merges** the chunks into a single `FILE_<contentId>`
   and deletes the parts.
3. Each `FILE_<contentId>` is actually a **ZIP** (magic `50 4B 03 04`).
4. During/after flashing these files may be **deleted**, so capture must start before
   or as soon as the flash begins.

### Metadata files (same folder)
- `services.json` → **content ↔ version map** (the most valuable file; also embeds the
  ESS distribution API URLs and the device session tokens — see the ESS API doc).
- `products.json` → product catalogue.
- `secstate.json` → Sony signing / security-state hash list (not device-specific).

## Example firmware (from `services.json`)

- Model **XQ-CT72**, platform **PDX223**, Android **14**, build **64.2.A.2.265**,
  customization `XQ-CT72_Customized_SEA`.

| contentId | file | type |
|-----------|------|------|
| 21034045 | `APP-SW_PDX223_GLOBAL-C2_USER_64.2.A.2.265_X-FLASH-ALL-6348_COM.zip` (~3.76 GB) | APP_SW |
| 21018365 | `Elabel_…_XQ-CT72_SEA_…zip` | E_LABEL |
| 21015445 | `CustomerID_…_SEA_…zip` | CUSTOMER_ID |

### Inside the main firmware ZIP (27 entries)
Full partition set as `.sin`: `boot`, `super`, `vendor_boot`, `dtbo`, `recovery`,
`oem`, `modem`, `dsp`, `persist`, `bluetooth`, `vbmeta`, `vbmeta_system`, `metadata`,
`misc`, `modemst1/2`, `cdt`, `diag`, `appslog`, `featenabler`, `userdata` + `update.xml`,
`partition.zip`, `boot.zip`, `odm.map`, `osv-restriction.ta`, `securitypatchlevel.dat`.

→ For root, extract `boot_*.sin` → raw `boot.img` (strip the SIN header to the
`ANDROID!` magic) → patch → flash.

## Capture tool

`firmware-capture/watch_firmware_win.ps1` watches the Companion data tree (minus the
static install dirs) and copies any firmware part/`.sin`/large file to a destination
folder as it appears, filtering out system TEMP noise. The most reliable approach once
the parts merge: as the flash starts, `robocopy "<…localstorage\REGION>" <dest> /E /MT:16`
to grab everything before Companion deletes it.
