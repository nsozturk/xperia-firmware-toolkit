# Sony ESS Distribution API — direct, Companion-less firmware download

The session tokens in Xperia Companion's `localstorage\<REGION>\services.json` let
you query Sony's **public** ESS distribution API directly. No MITM, no SSL-pinning
bypass, no Companion. Verified end-to-end (HTTP 200/206).

## The chain (3 steps)

### 1) software-service — the file list for one build
```
GET https://app.swup.update.sony.net/ess-distribution/public/api/device-service/software-service/gen2/<metaServiceId>?MiscPackageId=…&password=…&MiscPassword=…&AndroidVersionUpdateType=TARGET&CeParam=…
```
Returns XML: model (e.g. XQ-CT72 / PDX-223), software version, Android version,
customization, anti-rollback counters, and a `file-resource` per file
(content-id + a `file-chunk-info` link).

### 2) file-chunk-info — the chunk list for one file
```
GET …/ess-distribution/public/api/file/<contentId>?password=<fileToken>
```
Returns XML: a `file-chunk number=N` per chunk, each with a `download` link.

### 3) filestorage — the direct CDN download (Range-capable)
```
GET https://app.swup.update.sony.net/filestorage/<contentId>/<hash>_part<N>
```
- `application/octet-stream`, each chunk 104857600 bytes (last chunk partial).
- **HTTP 206 + Accept-Ranges** → fetch chunks in parallel / resume with Range.
- Concatenate `part0..partN` to reassemble the original file (e.g. the APP-SW firmware ZIP).

Redacted example responses are in [`examples/`](../examples/):
`software-service.example.xml` and `file-chunk-info.example.xml`.

## On the tokens

`password`, `MiscPassword`, `CeParam` and each per-file `password` come from a
**device handshake session** (performed before `software-service`). The tokens
captured in a real session work but can expire. To enumerate **other** builds/models
you must repeat the handshake — which is exactly what **XperiFirm** already
implements (it speaks Sony's GCS/ESS protocol and lists every available version per
model).

## "Download all versions" — the practical picture

- **Enumeration:** use XperiFirm (or implement the device-service handshake yourself).
- **Download:** the `filestorage` chunk URLs above, in parallel, with Range.
- **Reality:** Sony keeps only the **latest** firmware per customization online; older
  builds are removed from Sony's servers (only community archives keep history).
- **Redistribution note:** Sony firmware is proprietary/copyrighted — don't re-host it
  publicly.
