# DoseBreaker

A root module for Android that disables EU safe media volume enforcement, including the CSD (Content Sound Dosimetry) system introduced in Android 14.

Supports **Magisk**, **KernelSU**, and **APatch**.

---

## The Problem

EU regulations require Android devices to automatically reduce headphone volume after a period of loud listening. Android implements this through two systems:

**Legacy safe media volume** — an index-based system that limits volume above a threshold and re-enables after ~20 hours of cumulative listening.

**CSD (Content Sound Dosimetry)** — a newer system introduced in Android 14 that measures actual sound exposure using MEL (Mean Energy Level). It accumulates dose in-memory within AudioService and triggers volume reduction at 100% of the weekly dose threshold. As of Android 16 / LineageOS 23.2, the accumulator is managed entirely at runtime with no persistent settings keys.

There is no user-facing toggle to disable either system.

---

## What This Module Does

This module targets safe volume enforcement at multiple layers and continuously counteracts it at runtime.

### Core enforcement bypass
- Resets the CSD dose accumulator directly via `cmd audio set-sound-dose-value 0.0`
- Resets the momentary exposure timeout via `cmd audio reset-sound-dose-timeout`
- Forces legacy safe volume state to disabled via the settings database

### Persistent runtime enforcement
- Runs a background daemon (`service.sh`)
- Continuously resets the CSD accumulator and legacy settings overrides
- Uses an adaptive loop (aggressive at boot, lower overhead at steady state)
- Prevents vendor services from re-enabling enforcement

### Adaptive audio system handling
- Detects audio mods at install time:
  - JamesDSP
  - ViPER4Android
- Applies compatibility tweaks to prevent conflicts with DSP chains

### Audio pipeline tuning
- Sets resampler quality to 7 on all devices
- Enables audio offload and deep buffer for sustained playback quality

---

## Why a Maintenance Loop?

Modern Android offloads parts of audio policy enforcement to vendor services in `/vendor/`.

These services:
- Periodically recalculate and re-enable CSD
- Override userland changes to the dose accumulator

Because `/vendor/` is read-only and device-specific, the module uses a **persistent enforcement loop** instead:

- Early boot: aggressive enforcement (every ~30 seconds)
- Steady state: reduced overhead (~2 minutes)
- Periodically reapplies audio configuration to counter system overrides

This keeps the CSD accumulator effectively pinned near zero under normal use.

---

## Requirements

- Android 12+
- Tested on Android 16 (LineageOS 23.2)
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
# Current CSD dose value
cmd audio get-sound-dose-value

# Full CSD state and update log
dumpsys audio | grep -A2 -B2 "Csd\|mCurrentCsd\|mEnableCsd"

# Legacy safe volume state
dumpsys audio | grep "mSafeMediaVolume"
```

Module log:

```
/data/adb/modules/disable_safe_media_volume/log.txt
```

---

## Tested On

| Device          | OS                          | Root   |
| --------------- | --------------------------- | ------ |
| Pixel 8 (shiba) | LineageOS 23.2 (Android 16) | Magisk |

If you've tested on other devices, open an issue or PR to expand this table.

---

## Known Limitations

- Some OEMs heavily modify audio frameworks, which may require additional adaptation
- The module cannot patch `/vendor/`, so continuous enforcement is required
- `cmd audio set-sound-dose-value` requires Android 14+ — on older versions the legacy settings layer is the only enforcement mechanism

---

## Versioning

Format: `vMAJOR.MINOR.PATCH`

* **Major** → architectural changes (e.g. v2 → v3 runtime enforcement)
* **Minor** → new features / detection improvements
* **Patch** → fixes, stability improvements

---

## Contributing

Issues and PRs are welcome.

If something doesn't work:

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
