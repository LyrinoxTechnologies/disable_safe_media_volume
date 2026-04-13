# DoseBreaker

> NOTE: On the latest version of LineageOS, this does not reliably work. A fix will be published as soon as one can be found.

A root module for Android that disables EU safe media volume enforcement, including the CSD (Content Sound Dosimetry) system introduced in Android 14.

Supports **Magisk**, **KernelSU**, and **APatch**.

---

## The Problem

EU regulations require Android devices to automatically reduce headphone volume after a period of loud listening. Android implements this through two systems:

**Legacy safe media volume** — an index-based system that limits volume above a threshold and re-enables after ~20 hours of cumulative listening.

**CSD (Content Sound Dosimetry)** — a newer system introduced in Android 14 that measures actual sound exposure using MEL (Mean Energy Level). It accumulates dose across reboots via the settings database and triggers volume reduction at 5× the safe dose threshold.

There is no user-facing toggle to disable either system.

---

## What This Module Does

This module targets safe volume enforcement at multiple layers and continuously counteracts it at runtime:

### Core enforcement bypass
- Calls `disableSafeMediaVolume()` via binder (best effort)
- Resets CSD (SoundDose) accumulator at runtime
- Clears persisted CSD dose records on every boot and continuously during runtime
- Forces safe volume state to disabled via settings database

### Persistent runtime enforcement
- Runs a background daemon (`service.sh`)
- Continuously reapplies CSD resets and settings overrides
- Uses an adaptive loop (fast at boot, lower overhead later)
- Prevents vendor services from re-enabling enforcement

### Adaptive audio system handling
- Detects audio HAL type:
  - AIDL
  - Vendor HIDL (Qualcomm and others)
  - Generic fallback
- Detects audio mods:
  - JamesDSP
  - ViPER4Android
- Applies compatibility tweaks to prevent conflicts with DSP chains

### Smart audio pipeline tuning
- Dynamically configures resampler quality:
  - Safe mode (`quality=4`) for universal compatibility
  - High-quality dynamic mode (`quality=7`) when supported
- Applies advanced PSD resampler tuning only on supported devices
- Avoids unsafe values that can crash `audioserver`

---

## Why a Maintenance Loop?

Modern Android offloads parts of audio policy enforcement to vendor services in `/vendor/`.

These services:
- Periodically re-enable CSD
- Recalculate exposure dose
- Override userland changes

Because `/vendor/` is read-only and device-specific, the module uses a **persistent enforcement loop** instead:

- Early boot: aggressive enforcement (every ~30 seconds)
- Steady state: reduced overhead (~2 minutes)
- Periodically reapplies audio configuration to counter system overrides

This keeps the CSD accumulator effectively pinned near zero under normal use.

---

## Requirements

- Android 12+
- Tested on Android 16 (LineageOS 23)
- One of the following:
  - [Magisk](https://github.com/topjohnwu/Magisk) v20.4+
  - [KernelSU](https://github.com/tiann/KernelSU)
  - [APatch](https://github.com/bmax121/APatch)

---

## Installation

1. Download the latest zip from  
   https://github.com/LyrinoxTechnologies/dosebreaker/releases/latest
2. Open Magisk / KernelSU / APatch
3. Go to Modules → Install from storage
4. Select the downloaded zip
5. Reboot

---

## Debugging

Run these in a root shell:

```bash
# Current CSD level
dumpsys audio | grep -a "mCurrentCsd"

# Full CSD / SoundDose logs
dumpsys audio | grep -a "CSD"

# SoundDose accumulator
dumpsys audio | grep -a "doser"
````

Module log:

```
/data/adb/modules/disable_safe_media_volume/log.txt
```

---

## Tested On

| Device          | OS                        | Root   |
| --------------- | ------------------------- | ------ |
| Pixel 8 (shiba) | LineageOS 23 (Android 16) | APatch |

If you've tested on other devices, open an issue or PR to expand this table.

---

## Known Limitations

* Binder transaction IDs are not stable across all devices

  * Treated as best-effort only
* Some OEMs heavily modify audio frameworks, which may require additional adaptation
* The module cannot patch `/vendor/`, so continuous enforcement is required
* Advanced resampler tuning is only applied when supported to avoid instability

---

## Versioning

Format: `vMAJOR.MINOR.PATCH`

* **Major** → architectural changes (e.g. v2 → v3 runtime enforcement)
* **Minor** → new features / detection improvements
* **Patch** → fixes, stability improvements

---

## Contributing

Issues and PRs are welcome.

If something doesn’t work:

* Include device model
* Android version
* Root manager
* Logs (`log.txt`)

---

## Support Lyrinox Technologies

If this module helped you, consider sponsoring:

[https://github.com/sponsors/LyrinoxTechnologies](https://github.com/sponsors/LyrinoxTechnologies)

---

## License

GNU GPL v3.0 — see [LICENSE](LICENSE)

You are free to use, modify, and distribute this module, but derivative works must remain open source under GPLv3.

---

*Built and maintained by Vetheon @ Lyrinox Technologies*
