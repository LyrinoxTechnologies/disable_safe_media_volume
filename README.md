# Disable Safe Media Volume

A root module for Android that disables the EU safe media volume enforcement,
including the CSD (Content Sound Dosimetry) system introduced in Android 14.

Supports **Magisk**, **KernelSU**, and **APatch**.

---

## The Problem

EU regulations require Android devices to automatically reduce headphone volume
after a period of loud listening. Android implements this through two systems:

**Legacy safe media volume** — an index-based system that limits volume above a
threshold and re-enables after 20 hours of cumulative listening.

**CSD (Content Sound Dosimetry)** — a newer EU-mandated system introduced in
Android 14 that measures actual sound exposure using MEL (Mean Energy Level)
values. It accumulates dose across reboots via the settings database and triggers
a volume reduction at 5x the safe dose threshold. This is the primary cause of
the volume being automatically lowered on modern Android.

There is no toggle to disable either system in the Android settings UI.

---

## What This Module Does

Targets the enforcement at every layer:

- Installs a static resource overlay disabling `config_safe_media_volume_enabled`,
  `config_safe_sound_dosage_enabled`, and `config_safe_media_disable_on_volume_up`
  at the framework resource level — before AudioService ever reads them
- Sets `audio.safemedia.bypass` props to disable the legacy safe volume system
- Calls `disableSafeMediaVolume()` and `resetCsd()` directly via binder at boot
- Clears persisted CSD dose records from the settings database on every boot
- Resets the runtime CSD accumulator to zero on every boot

---

## Requirements

- Android 12+ (tested on Android 16 / LineageOS 23)
- One of the following:
  - [Magisk](https://github.com/topjohnwu/Magisk) v20.4+
  - [KernelSU](https://github.com/tiann/KernelSU)
  - [APatch](https://github.com/bmax121/APatch)

---

## Installation

1. Download the latest zip from [Releases](https://github.com/LyrinoxTechnologies/disable_safe_media_volume/releases/latest)
2. Open Magisk / KernelSU / APatch
3. Go to Modules → Install from storage
4. Select the downloaded zip
5. Reboot

---

## Tested On

| Device | OS | Root |
|---|---|---|
| Pixel 8 (shiba) | LineageOS 23 (Android 16) | APatch 11142 |

If you've tested on other devices, open an issue or PR to expand this table.

---

## Versioning

Format: `vMAJOR.MINOR.PATCH`

Major versions mark significant rewrites or architectural changes.
Minor versions mark new features.
Patch versions mark fixes and small improvements.

---

## Contributing

Issues and PRs welcome. If you find a device where the module doesn't work,
open an issue with your device, Android version, and root manager.

---

## Support Lyrinox Technologies

If this module helped you, consider sponsoring us on GitHub so we can continue
building and maintaining free tools like this.

**[github.com/sponsors/LyrinoxTechnologies](https://github.com/sponsors/LyrinoxTechnologies)**

---

## License

This project is licensed under the GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.

In short: you are free to use, modify, and distribute this module, but any
derivative works must also be released under GPLv3 and remain open source.

---

*Built and maintained by [Vetheon](https://github.com/LyrinoxTechnologies) @ Lyrinox Technologies*