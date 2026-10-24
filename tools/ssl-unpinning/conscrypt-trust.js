/*
 * conscrypt-trust.js — blanket trust for com.android.org.conscrypt.TrustManagerImpl
 *
 * combined.js neutralizes known pinning libs and redirects traffic to the proxy,
 * but leaves the base trust-anchor decision to the system CA store. When an app's
 * conscrypt TrustManagerImpl still throws "Trust anchor for certification path not
 * found" (system CA not honored), this script forces TrustManagerImpl to accept the
 * presented chain. Research / MitM use on a controlled device only.
 *
 * Load together with combined.js:
 *   frida -U -f <pkg> -l combined.js -l conscrypt-trust.js
 */

Java.perform(function () {
    const TARGET = 'com.android.org.conscrypt.TrustManagerImpl';
    let TMI;
    try {
        TMI = Java.use(TARGET);
    } catch (e) {
        console.log('[conscrypt-trust] ' + TARGET + ' not present: ' + e);
        return;
    }

    let patched = 0;

    // checkServerTrusted overloads — return the chain (some overloads return List, some void).
    TMI.checkServerTrusted.overloads.forEach(function (ov) {
        try {
            ov.implementation = function () {
                const chain = arguments[0]; // X509Certificate[]
                try {
                    // Build a List<X509Certificate> from the chain for List-returning overloads.
                    const ArrayList = Java.use('java.util.ArrayList');
                    const list = ArrayList.$new();
                    if (chain) {
                        for (let i = 0; i < chain.length; i++) list.add(chain[i]);
                    }
                    return list;
                } catch (e) {
                    return; // void overloads
                }
            };
            patched++;
        } catch (e) {
            console.log('[conscrypt-trust] skip checkServerTrusted overload: ' + e);
        }
    });

    // checkTrustedRecursive (internal) — return chain as List, never throw.
    if (TMI.checkTrustedRecursive) {
        TMI.checkTrustedRecursive.overloads.forEach(function (ov) {
            try {
                ov.implementation = function () {
                    const chain = arguments[0];
                    const ArrayList = Java.use('java.util.ArrayList');
                    const list = ArrayList.$new();
                    try {
                        if (chain) { for (let i = 0; i < chain.length; i++) list.add(chain[i]); }
                    } catch (e) {}
                    return list;
                };
                patched++;
            } catch (e) {
                console.log('[conscrypt-trust] skip checkTrustedRecursive overload: ' + e);
            }
        });
    }

    console.log('[conscrypt-trust] patched ' + patched + ' TrustManagerImpl method(s) — blanket trust active.');
});
