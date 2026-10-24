# Xperia Companion (Windows) — Stock Firmware Yakalama Yöntemi

Tarih: 2026-10-21
Cihaz: Sony Xperia 1 IV — **XQ-CT72** (PDX223), GLOBAL-C2 / SEA
Bağlam: Cihaz bootloop'taydı. Sony firmware'ini internette yayınlamıyor; tek
yol Xperia Companion "Software repair". Amaç: repair sırasında indirilen stock
firmware'i diskten yakalayıp saklamak (RE yok, sadece drop noktasını izleme).

## Nereye düşüyor (KESİN)

Companion kurulum/veri kökü:
`C:\Users\<user>\AppData\Local\Sony\Xperia Companion\`
- Statik: `jre\`, `plugins\`, `configuration\`, `licenses\`, `setup\`
- Çalışma dizini (kurulum zamanı damgalı): `<InstallTime>\`  (örn. `2026-10-21-150253`)
  - `log\`  → Sony şifreli binary log (düz okunmaz)
  - `temp\`, `workspace\` → firmware BURAYA düşmedi
  - **`localstorage\<REGION>\`  (örn. `localstorage\US\`) → FIRMWARE BURAYA DÜŞÜYOR**

### İndirme mekaniği
1. Önce `FILE_<contentId>_part0 … partN` adıyla **100 MB'lık parçalar** iner.
2. İndirme %100 olunca Companion parçaları tek dosyaya **birleştirir** ve
   parçaları siler. Nihai ad: `FILE_<contentId>` (uzantısız).
3. Her `FILE_<contentId>` aslında bir **ZIP** (magic `50 4B 03 04`).
4. "Repairing device" (flash) aşamasında/sonrasında bu dosyalar **silinebilir**,
   bu yüzden flash başlamadan / başlar başlamaz kopyalamak şart.

### Metadata dosyaları (aynı klasörde)
- `services.json` → **içerik↔versiyon eşlemesi** (asıl değerli dosya; aşağıda).
- `products.json` → ürün kataloğu.
- `secstate.json` → Sony imza/güvenlik-durumu hash listesi (cihaza özel değil).

## Bu indirmenin bilgileri (services.json)

- Model: **XQ-CT72**, Platform: **PDX223**, Android: **14**
- Software Revision (APP_SW): **64.2.A.2.265**
- Customization: `XQ-CT72_Customized_SEA`, SPC: 43040691 / 43040689
- Security state: COMMERCIAL
- Dağıtım API'si: `https://app.swup.update.sony.net/ess-distribution/public/api/device-service/...`

| contentId | FILE_ | tip | ad |
|---|---|---|---|
| 21034045 | FILE_21034045 (3.76 GB) | APP_SW | `APP-SW_PDX223_GLOBAL-C2_USER_64.2.A.2.265_X-FLASH-ALL-6348_COM.zip` |
| 21018365 | FILE_21018365 (1.53 MB) | E_LABEL | `Elabel_S20000507_..._XQ-CT72_SEA_X-FLASH-LTALABEL-6348.zip` |
| 21015445 | FILE_21015445 (415 B) | CUSTOMER_ID | `CustomerID_S20000481_001_SEA_c001707.zip` |

### Ana firmware ZIP (FILE_21034045) içeriği — 27 girdi
Tam partition seti (.sin = Sony formatı):
`boot(96MB)`, `super(3976MB)`, `vendor_boot(96MB)`, `dtbo(24MB)`, `recovery(100MB)`,
`oem(364MB)`, `modem(115MB)`, `dsp(64MB)`, `persist(32MB)`, `bluetooth`, `vbmeta`,
`vbmeta_system`, `metadata`, `misc`, `modemst1/2`, `cdt`, `diag`, `appslog`,
`featenabler`, `userdata` + `update.xml`, `partition.zip`, `boot.zip`,
`odm.map`, `osv-restriction.ta`, `securitypatchlevel.dat`

→ **Root için:** `boot_X-FLASH-ALL-6348.sin` çıkar → .sin'i ham img'e aç
   (unsin / sinextract / anyxperia `sony_dump`) → Magisk/APatch yamala →
   `fastboot flash boot <patched>`.

## Yakalama aracı
`xperia1_iv_root/watch_firmware_win.ps1` (v3): Companion ağacını izler
(statik klasörler hariç), >2MB veya firmware adı/uzantısı eşleşenleri anlık
`captured_stock_firmware/`'e kopyalar; sistem %TEMP%'te sadece firmware-benzeri
adları alır. Parça birleştirme sonrası en garantisi: flash başlar başlamaz
`robocopy "<localstorage\US>" <hedef> /E /MT:16` ile komple kopyalamak.

Yakalanan (byte-exact doğrulandı):
`xperia1_iv_root/captured_stock_firmware/localstorage_US_21034045/`

## "Tüm versiyonları indirip yayınlama" hedefi için
- Manuel Companion-capture ölçeklenmez. Ölçeklenebilir yol:
  **XperiFirm** (model başına tüm firmware versiyonlarını Sony ESS sunucusundan
  doğrudan `.sin`/FTF olarak çeker — cihaz gerekmez) veya services.json'daki
  `app.swup.update.sony.net/ess-distribution` API'sini doğrudan sorgulamak.
- contentId şeması (21034045 vb.) ve `GLOBAL-C2 / SEA / HwSetup=Default`
  parametreleri bu API üzerinden versiyon enumerasyonunun anahtarı.
