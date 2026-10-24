# Xperia 1 IV (XQ-CT72 / PDX223) Root Kılavuzu — Android 14

Sony Xperia 1 IV'ü sıfırdan rootlamak için eksiksiz kaynak + rehber.
En zor kısım (Sony firmware'ini çekmek) dahil, baştan sona.

> **Cihaz:** XQ-CT72 (SEA/çift SIM) · **Platform:** PDX223 · **SoC:** SM8450 (SD 8 Gen 1)
> **Android:** 14 · **Build (örnek):** 64.2.A.2.265 · **Kernel:** GKI 2.0 (5.10)

---

## ⚠️ Önce oku

- **Bootloader açmak cihazı TAMAMEN siler** (factory reset) ve Sony'de **DRM
  anahtarlarını kalıcı iptal eder** (bazı kamera/ekran özellikleri etkilenebilir).
- Yanlış `boot.img` flash'lamak **bootloop** yapar — bu repo'daki boot.img
  **64.2.A.2.265 sürümüne** aittir. Cihazındaki sürüm farklıysa **kendi
  sürümünün** boot.img'ini kullan (bkz. Bölüm 1).
- Her şey **kendi cihazın / güvenlik araştırman** içindir.

---

## Gerekenler (bu kit'te hazır)

| Klasör | İçerik |
|---|---|
| `00_boot_stock/` | Stok `boot_64.2.A.2.265.img` (yamalanacak) |
| `01_kernelsu_next/` | **KernelSU Next** APK (asıl yöntem) |
| `02_magisk/` | **Magisk** APK (alternatif) |
| `03_apatch/` | APatch APK (alternatif) |
| `10_modules/` | ZygiskNext, Shamiko, TrickyStore, PlayIntegrityFork |
| `20_platform-tools/` | adb + fastboot (Windows) |

Ayrıca: Sony **bootloader unlock kodu** (IMEI ile Sony'den alınır — aşağıda).

---

## Bölüm 0 — Stok firmware'i çekmek (asıl zor kısım)

Sony firmware'i halka açık yayınlamaz. İki yol:

### Yol A — Xperia Companion'dan yakalama (Windows)
1. Xperia Companion kur, **bootloader KİLİTLİYKEN** (Companion açık BL'de çalışmaz).
2. Firmware indirme sırasında şuraya düşer:
   `%LOCALAPPDATA%\Sony\Xperia Companion\<tarih>\localstorage\<BÖLGE>\`
   Önce `FILE_<id>_partN` (100 MB parçalar), sonra birleşip `FILE_<id>` (ZIP) olur.
3. "Repairing device" başlar başlamaz o klasörü kopyala (flash sonrası silinebilir):
   `robocopy "<...localstorage\US>" <hedef> /E /MT:16`
4. `services.json` → hangi `FILE_<id>` hangi sürüm, eşlemesi burada.

### Yol B — Sony ESS API'den doğrudan (Companion'sız)
`services.json`'daki oturum token'larıyla public API doğrudan çalışır:
```
software-service → /api/file/<contentId>?password=<tok> → /filestorage/<id>/<hash>_partN
```
`/filestorage/...` parçaları **Range destekli**, doğrudan indirilir (bkz.
`research/2026-10-21_sony-ess-distribution-api-direct-download.md`).

---

## Bölüm 1 — Stok boot.img çıkarma (.sin → .img)

Firmware ZIP'inde `boot_X-FLASH-ALL-XXXX.sin` var (Sony SIN formatı, ham değil).
SIN header'ı `ANDROID!` magic'ine kadar (bu sürümde **3584 bayt**) soyulur:

```bash
# PowerShell / herhangi bir dille: ilk 3584 baytı at, gerisi boot.img
# (offset, .sin içinde 'ANDROID!' magic'inin konumu — sürüme göre değişebilir)
```
Doğrulama: çıkan dosya `ANDROID!` ile başlamalı, header_version = 4 olmalı.
Bu kit'teki `00_boot_stock/boot_64.2.A.2.265.img` hazır çıkarılmış hâlidir.

---

## Bölüm 2 — Bootloader açma (CİHAZI SİLER)

1. `developer.sony.com/open-devices/unlock-bootloader` → IMEI gir → unlock kodu al.
   (IMEI: `*#06#`)
2. Cihazı kapat → **Volume UP basılı tutup USB tak** → **mavi LED** = fastboot.
3. ```bash
   fastboot devices
   fastboot oem unlock 0x<UNLOCK_KODU>
   ```
4. Cihaz silinir ve yeniden başlar. Kurulumu geç, **Geliştirici Seçenekleri →
   USB hata ayıklama** ve **OEM unlock** açık kalsın.

---

## Bölüm 3A — Root: KernelSU Next (ASIL yöntem, Magisk'siz)

GKI cihaz olduğu için **LKM modu** (uygulama stok boot.img'i yamalar):

1. `01_kernelsu_next/KernelSU_Next-*.apk`'yi telefona at, kur.
2. `00_boot_stock/boot_64.2.A.2.265.img`'i telefona kopyala.
3. KernelSU Next uygulaması → **Install → Select and Patch a File** → stok
   boot.img'i seç → çıktı: `kernelsu_next_patched_*.img` (Download'a düşer).
4. Patched img'i PC'ye al, fastboot moduna geç:
   ```bash
   fastboot flash boot kernelsu_next_patched.img
   fastboot reboot
   ```
5. Açılışta KernelSU Next uygulaması "Çalışıyor / <sürüm>" göstermeli.
6. Modül desteği için **ZygiskNext** gerekir (Bölüm 4).

---

## Bölüm 3B — Root: Magisk (alternatif)

1. `02_magisk/Magisk-*.apk`'yi kur.
2. Stok `boot.img`'i telefona kopyala.
3. Magisk → **Install → Select and Patch a File** → boot.img → `magisk_patched_*.img`.
4. ```bash
   fastboot flash boot magisk_patched.img
   fastboot reboot
   ```
5. Magisk'te **Zygisk = Açık**, **Enforce DenyList** (veya Shamiko).

---

## Bölüm 4 — Zygisk + Play Integrity zinciri

Root sonrası (Magisk Settings veya KernelSU/APatch'te ZygiskNext üzerinden):

1. **Zygisk aç** — Magisk: dahili; KernelSU Next / APatch: `10_modules/ZygiskNext-*.zip` kur.
2. **Shamiko** (`10_modules/Shamiko-*.zip`) — root gizleme (Magisk DenyList'i
   "whitelist" moduna al, Shamiko'yu kur).
3. **TrickyStore** (`10_modules/TrickyStoreOSS-*.zip`) — keybox ile STRONG/DEVICE
   integrity. `keybox.xml`'i `/data/adb/tricky_store/`'a koy, `target.txt` ayarla.
4. **PlayIntegrityFork** (`10_modules/PlayIntegrityFork-*.zip`) — cihaz fingerprint
   spoof. Gerekirse güncel `pif.json` koy.
5. GMS/Play Store verisini temizle, cihazı yeniden başlat, Play Integrity test et.

---

## Hızlı komutlar

```bash
adb devices                       # cihaz açık + debug
adb reboot bootloader             # fastboot'a geç (ya da Vol+ ile USB)
fastboot devices
fastboot getvar unlocked          # bootloader açık mı
fastboot flash boot <patched>.img
fastboot reboot
```

## Sorun giderme
- **Bootloop:** yanlış/uyumsuz boot.img. Stok `boot.img`'i geri flash'la, sürümü doğrula.
- **Companion "driver missing":** Companion'ı **yönetici** çalıştır; SOMC Flash
  sürücüsü bozulduysa `C:\Program Files\Sony\SWUP-drivers\DriverInstaller64.exe` (admin).
- **fastboot cihazı görmüyor:** Google USB driver / Sony SWUP driver; farklı USB portu.
```
