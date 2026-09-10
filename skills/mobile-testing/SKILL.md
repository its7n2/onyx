---
name: mobile-testing
description: Mobile application security testing for authorized pentest targets — Android-first static and dynamic analysis (apktool, jadx, MobSF, adb, Frida/objection), certificate pinning and root-detection bypass, Network Security Config review, insecure data storage, and iOS checks where the tooling allows. Use when the user says mobile testing, Android, APK, iOS, IPA, MobSF, Frida, objection, pinning bypass, or is running a mobile engagement.
---

# Mobile Application Testing

Android-first (the realistic path from a Kali setup), iOS covered where tooling allows. The app package must be in `scope.md` by name/bundle ID. Test against production builds the customer provided or store builds they authorized.

## Setup

- Device: rooted Android (or emulator — Android Studio AVD / Genymotion / Corellium if available). `adb devices` to confirm.
- Static tooling on Kali: `apktool`, `jadx`, `MobSF` (docker run), `apkleaks`, `keytool`.
- Dynamic tooling: Frida server on the device matching host version, `objection patchapk` for non-rooted devices.
- Working dir: `<activity>/mobile/` — `static/`, `dynamic/`, `evidence/` screenshots.

## Phase 1 — Static analysis (Android)

```bash
apktool d app.apk -o static/apktool
jadx app.apk -d static/jadx
apkleaks -f app.apk -o static/secrets.txt
```

Work the checklist; record hits per finding file as you go:
- **Secrets & keys:** `apkleaks` + grep `static/jadx` for API keys, AWS creds, Firebase configs, hardcoded tokens, signing keys. Firebase open database check (`https://<proj>.firebaseio.com/.json`).
- **Manifest:** `android:debuggable`, `android:allowBackup`, exported activities/receivers/providers (`adb shell am start` exported components directly), permission abuse.
- **Network Security Config:** `network_security_config.xml` — `cleartextTrafficPermitted="true"`, trust anchors including user CAs? (If user CAs trusted → plain Burp MITM works; if not → pinning/bypass needed.)
- **Crypto:** hardcoded IVs, ECB mode, home-grown crypto in jadx output.
- **Webviews:** `setJavaScriptEnabled` + `addJavascriptInterface`, file:// access, URL validation gaps.
- MobSF for a fast automated baseline — treat output as leads, not findings (verify everything).

## Phase 2 — Bypass the controls (dynamic prep)

- **SSL pinning bypass:** `objection -g <package> explore` → `android sslpinning disable`; or Frida scripts (frida-codeshare) matched to the app's framework (OkHttp, Unity, flutter — flutter needs its own bypass).
- **Root detection:** objection `android root disable` or targeted Frida hooks on the detected check.
- Confirm the proxy path first: device WiFi → Burp, CA installed as **system** cert on the rooted device (`magisk` module or manual remount on emulator).

## Phase 3 — Dynamic testing

- **Traffic:** run the app through the workflows, capture all API traffic into Burp — every request feeds the `api-testing` matrix (BOLA, authz, injection). Mobile apps are API frontends; the juicy bugs usually live server-side.
- **Data at rest:** after exercising the app, pull and inspect —
  ```bash
  adb backup -f backup.ab <package>   # if allowBackup
  adb shell run-as <package> ls       # debuggable builds
  adb shell ls /data/data/<package>/
  ```
  Look for: tokens/PII in SharedPreferences (XML, often base64 — decode), SQLite DBs unencrypted, secrets in logs (`adb logcat`), files on external storage world-readable.
- **IPC:** exported components from Phase 1 — invoke with `am`/`content` commands, send crafted intents, check for activity injection and provider traversal.
- **Deep links:** enumerate from manifest, trigger `adb shell am start -a android.intent.action.VIEW -d "<url>"`, test parameter handling (auth bypass via deep link is common).
- **Keystore usage:** tokens cached via fingerprint-gated keystore — check enforcement is server-side too.

## Phase 4 — iOS (where tooling allows)

From Windows+Kali the realistic path: IPA from the customer → static only on Kali (`class-dump-z` limited; prefer `MobSF` static for IPA). Decrypted-store builds need a jailbroken device + `frida-ios-dump` — if the operator has one, run the equivalent checklist: Info.plist flags, NSAllowsArbitraryLoads in NSAppTransportSecurity, keychain data via Frida/objection (`ios keychain dump`), traffic via remote SSH proxy. No jailbreak = static + server-side testing only; say so in the report methodology.

## Evidence & findings

- Screenshots (device + Burp) into `evidence/`; every finding one file in `<activity>/findings/` per `templates/finding.md`.
- Server-side issues found through the app's API are findings against the API — cross-reference `api-testing`, one finding file, asset noted as the endpoint.

## Rules

- Test only the package(s) named in `scope.md` — store updates mid-engagement get re-checked before testing continues.
- No distribution/leakage of the app or the customer's signing material; the binary stays in the activity folder.
- Frida/objection hooks that trigger anti-fraud or backend alerts — coordinate with the customer contact per `roe.md` escalation flow.
