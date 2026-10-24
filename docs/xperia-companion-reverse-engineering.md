# Reverse-Engineering Xperia Companion (Windows)

How Sony's **Xperia Companion** desktop app works internally, where it puts
firmware, and how its network and firmware formats were analysed — enough to
pull stock firmware without the GUI. Observed on Companion **26.7.1** (Windows).

> For research on your own device. No Sony code or firmware is redistributed here.

---

## 1. App architecture

Xperia Companion is a **Java / Eclipse RCP (OSGi / Equinox)** application, not a
native one. Install root:

```
%LOCALAPPDATA%\Sony\Xperia Companion\
├─ Xperia Companion.exe          Equinox launcher
├─ Xperia Companion.ini          -vmargs (JVM flags, osgi areas)
├─ jre\                          bundled JRE (its own truststore!)
├─ plugins\                      OSGi bundles (*.jar)  ← all the logic
└─ <InstallTime>\               per-install data dir
   ├─ localstorage\<REGION>\    product + firmware state  ← firmware lands here
   ├─ temp\  workspace\  updates\
   └─ log\                      Sony-encrypted binary log (not plain text)
```

Interesting OSGi bundles in `plugins\` (names tell the story):
- `com.sonymobile.cs.ma.download_*` — download engine
- `com.sonymobile.cs.ma.fc.localstorage_*` — local firmware-content store
- `com.sonymobile.swup.ma.client.repair_*` — "Software repair" flow
- `com.sonymobile.swup.ma.client.product.metadata.service_*` — metadata/ESS
- `com.sonymobile.swup.network.httpclient_*` — Apache HttpClient 5 transport
- `com.sonymobile.cs.usbflashnative.*`, `com.sonymobile.cs.s1sl.*` — USB flashing

Because it is a Java app, it honours standard JVM system properties and — crucially
— uses **its own bundled truststore**, which is the key to interception (§3).

---

## 2. How firmware is downloaded (observed)

During "Software repair" the download engine writes into
`…\<InstallTime>\localstorage\<REGION>\` (e.g. `localstorage\US\`):

1. First as **100 MB chunks** named `FILE_<contentId>_part0 … _partN`.
2. On completion the chunks are **concatenated** into `FILE_<contentId>` and the
   parts are deleted.
3. Each `FILE_<contentId>` is actually a **ZIP** (magic `50 4B 03 04`). The main
   one is the full firmware bundle (all partition `.sin` files + `update.xml`).
4. During/after flashing these files may be deleted, so capture must start before
   or as the flash begins. See `firmware-capture/watch_firmware_win.ps1`.

### Metadata files (same folder)
- **`services.json`** — the valuable one: maps each `FILE_<contentId>` to its
  software version, file name and type (`APP_SW`, `E_LABEL`, `CUSTOMER_ID`), and
  embeds the live **ESS distribution API** URLs + the device session tokens.
- `products.json` — product catalogue.
- `secstate.json` — Sony signing / security-state hash list (not device-specific).

---

## 3. Intercepting the traffic (the JRE-truststore trick)

The goal was to see exactly where the app requests firmware. Key facts:

- The app uses **Apache HttpClient 5** over TLS. Standard HTTPS, no hard
  certificate pinning observed — a trusted MITM CA is enough.
- **Java ignores the Windows certificate store.** Adding your proxy CA to Windows
  does nothing. The app trusts only its **bundled JRE truststore**:
  `…\Xperia Companion\jre\lib\security\cacerts` (default password `changeit`).

Method (see `mitm/`):

1. Run mitmproxy (pure Python, no separate app) to generate its CA.
2. Inject the CA into the **JRE** truststore with the bundled `keytool`:
   ```
   jre\bin\keytool -importcert -alias mitmproxy -file mitmproxy-ca-cert.pem \
     -keystore jre\lib\security\cacerts -storepass changeit -noprompt
   ```
   (back up `cacerts` first).
3. Route the app through the proxy — either JVM `-D…proxyHost` flags in the
   `.ini`, or a transparent per-process capture (`mitmdump --mode local:"Xperia Companion.exe"`,
   WinDivert, needs admin). The addon in `mitm/log_urls.py` logs every request URL
   and flags firmware/CDN hits.

> In the end the proxy was optional: the tokens already sit in `services.json`,
> so the ESS API can be called directly (see `sony-ess-api-direct-download.md`).

---

## 4. The ESS distribution protocol (summary)

`services.json` exposes Sony's **public** ESS distribution API. With a device
session's tokens the firmware can be fetched without Companion:

```
software-service  →  /api/file/<contentId>?password=…  →  /filestorage/<id>/<hash>_partN
```

Responses are plain XML; the final `filestorage` chunk URLs are direct,
`application/octet-stream`, and **HTTP Range-capable**. Full write-up and redacted
example responses: `sony-ess-api-direct-download.md` and `examples/`.

---

## 5. Sony SIN firmware format (boot extraction)

The partition images inside the firmware ZIP are Sony **`.sin`** files, not raw
images. For a kernel/boot image the layout is simply:

```
[ SIN header ]  [ raw Android boot image … ]
```

Find the Android boot magic `ANDROID!` (`41 4E 44 52 4F 49 44 21`) — on the
analysed build it begins at **offset 3584 (0xE00)**, i.e. the SIN header is 3584
bytes. Strip those leading bytes and the remainder is a valid boot image
(`header_version 4`), ready to patch. The flashed boot partition is exactly
`104857600 − 3584` padded; trim any trailing zero padding to the partition size
before `fastboot flash boot`.

---

## 6. USB flash driver note (Windows)

Companion's firmware/flash driver is a kernel component (`SOMCFlashDevice`,
`ggsomc.inf`, installed under `Program Files\Sony\SWUP-drivers`). If the app is
force-killed mid-flash the driver can enter an error state and Companion then
reports *"Driver for software update is missing"* — reinstall it as admin via
`DriverInstaller64.exe` (separate from the `fastboot` WinUSB driver, which is
installed with Zadig for bootloader work).
