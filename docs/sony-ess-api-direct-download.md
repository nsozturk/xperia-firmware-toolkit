# Sony ESS Distribution API — Companion'sız Doğrudan Firmware İndirme

Tarih: 2026-10-21
Keşif: Xperia Companion'ın `localstorage\US\services.json`'undaki oturum
token'ları ile Sony'nin **public** dağıtım API'si doğrudan sorgulanabiliyor.
MITM / SSL pinning kırma / sürücü / Companion GEREKMİYOR. Kanıtlandı (HTTP 200/206).

## Zincir (3 adım)

### 1) software-service — bir versiyonun dosya listesi
```
GET https://app.swup.update.sony.net/ess-distribution/public/api/device-service/software-service/gen2/<metaServiceId>?MiscPackageId=<id>&password=<tok>&MiscPassword=<tok>&AndroidVersionUpdateType=TARGET&CeParam=<tok>
```
Dönen XML: model (XQ-CT72 / PDX-223), software-version (64.2.A.2.265),
android-version, customization, anti-rollback sayaçları ve her dosya için
`file-resource` (content-id + `file-chunk-info` linki).

### 2) file-chunk-info — dosyanın parça (chunk) listesi
```
GET .../ess-distribution/public/api/file/<contentId>?password=<fileTok>
```
Dönen XML: `file-chunk number=N` + her biri için `download` linki.

### 3) filestorage — doğrudan CDN indirme (Range destekli)
```
GET https://app.swup.update.sony.net/filestorage/<contentId>/<hash>_part<N>
```
- `application/octet-stream`, her parça 104857600 B (son parça kısmi).
- **HTTP 206 + Accept-Ranges** → Range ile parça parça / paralel indirilebilir.
- part0..partN birleştir = orijinal dosya (ör. APP-SW ...zip = firmware FTF).

## Bu versiyonun somut değerleri (XQ-CT72 / 64.2.A.2.265 / A14)
- metaServiceId: `<REDACTED_ID>-COMMERCIAL_SUCE_GEN2`
- ProductObjectId: `<REDACTED_UUID>` (PDX-223)
- ModelObjectId: `<REDACTED_UUID>` (XQ-CT72)
- CustomizationId: `24616010`, DomainId: `170`, HwSetupKey: `Default`
- content 21034045 (APP_SW, 4032872824 B, 39 chunk) — ana firmware
- content 21018365 (E_LABEL), 21015445 (CUSTOMER_ID)
- Manifest + chunk XML kaydı: `xperia1_iv_root/ess_api/`

## Token'ların doğası (önemli)
`password`, `MiscPassword`, `CeParam` ve per-file `password` değerleri bir
**cihaz handshake oturumundan** geliyor (software-service çağrısından önce
device-service login/handshake yapılıyor). Yakaladığımız token'lar bu oturuma
ait ve çalışıyor; süresi dolabilir. BAŞKA versiyonları/modelleri enumerate
etmek için handshake'i tekrarlamak gerekir → bunu **XperiFirm** hazır yapıyor
(Sony GCS/ESS protokolünü implemente etmiş, model başına tüm sürümleri listeler).

## "Tüm versiyonları indirip yayınlama" için pratik yol
1. Enumerasyon: XperiFirm (veya device-service handshake'ini biz implemente).
2. İndirme: yukarıdaki filestorage chunk URL'leri, Range ile paralel.
3. Not: Firmware **Sony'nin telifli/özel yazılımı** — public yeniden dağıtım
   (GitHub) DMCA/ToS riski taşır; parça boyutu da GitHub asset sınırını aşıyor.
   Ayrıntı için ayrı değerlendirme.
