# Changelog

All notable changes to Disable Safe Media Volume will be documented here.

---

## [v2.0.0] - 2026-03-14

### Complete rewrite based on deep system investigation

### Added
- Resource overlay (`SafeMediaVolumeOverlay.apk`) targeting `android` framework package
  - Overrides `config_safe_media_volume_enabled` to false
  - Overrides `config_safe_sound_dosage_enabled` to false
  - Overrides `config_safe_media_disable_on_volume_up` to false
- Binder call `service call audio 102` to disable safe media volume at runtime
- Binder call `service call audio 108 f 0.0` to reset accumulated CSD dose to zero
- Clearing of persisted CSD settings database records on every boot
  - `audio_safe_csd_current_value`
  - `audio_safe_csd_dose_records`
  - `audio_safe_csd_next_warning`
- 35 second post-boot delay before applying binder calls to ensure AudioService has
  finished its configuration pass

### Changed
- Version bumped to v2.0.0 to reflect complete rewrite
- versionCode format changed to plain incrementing integer starting at 200

### Root cause findings
- The volume reduction was caused by Android's CSD (Content Sound Dosimetry) system
  accumulating exposure dose across reboots via the settings database
- The accumulated dose on test device had reached 69x the safe threshold
- Safe media volume state and CSD are two independent systems — disabling one does
  not disable the other
- System props (`audio.safemedia.bypass` etc) only affect the legacy index-based
  safe volume system, not CSD
- CSD is enabled via framework resource `config_safe_sound_dosage_enabled` which
  requires a resource overlay to override at the correct layer
- Binder transaction 102 on the audio service maps to `disableSafeMediaVolume()`
- Binder transaction 108 on the audio service maps to `resetCsd()`

### Fixed
- Previous version's props were targeting the wrong layer and had no effect on CSD
- `audio_safe_volume_state=3` in service.sh was actually setting the enforcing state
  instead of disabling it (corrected to 0)

---

## [v1.1.0] - 2026-03-14

### Added
- APatch and KernelSU support alongside existing Magisk support
- GitHub release-based auto-updating via `updateJson` in module.prop
- `update.json` for release tracking
- Custom installer UI with sponsor callout in `customize.sh`
- GitHub Actions workflow for automatic patch version bumping, packaging, tagging,
  and releasing

### Changed
- `audio_safe_volume_state` setting changed from `3` to `0`
- Expanded `system.prop` to target CSD enforcement
- Version format changed to semantic versioning `vMAJOR.MINOR.PATCH`
- `versionCode` decoupled from version string

### Fixed
- `ro.` prefixed props removed — were being ignored entirely

---

## [v1.0.0] - Initial Release

### Added
- Basic safe media volume prop patching
- Boot-completed service script
- Initial settings database overrides